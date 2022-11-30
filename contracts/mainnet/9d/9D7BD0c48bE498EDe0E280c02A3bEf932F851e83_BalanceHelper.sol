// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "IJoePair.sol";
import "IVoter.sol";
import "IMasterChefVTX.sol";
import "IMainStaking.sol";
import "IBoostedMultiRewarder.sol";
import "IMasterPlatypusv4.sol";
import "IJoeFactory.sol";
import "IBribeManager.sol";
import "IMasterChefVTX.sol";
import "ILockerV2.sol";
import "IBribe.sol";
import "IyyAvax.sol";
import "IAPRHelper.sol";
import "IBaseRewardPool.sol";
import "AggregatorV3Interface.sol";
import "IMainStakingJoe.sol";

import "IERC20.sol";

contract BalanceHelper is Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 internal constant ACC_TOKEN_PRECISION = 1e15;
    uint256 public constant AvaxUSDDecimals = 8;
    uint256 public constant precision = 8;
    address public wavax;
    address public yyAvax;
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public aprHelper;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 factor;
        uint256 accTokenPerShare;
        uint256 accTokenPerFactorShare;
    }
    //End of Storage v1

    struct HelpStack {
        address[] rewardTokens;
        uint256[] amounts;
    }

    // End of Storage v2

    constructor(
        address _wavax,
        address _aprHelper,
        address _yyAvax
    ) {
        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
        wavax = _wavax;
        aprHelper = _aprHelper;
        yyAvax = _yyAvax;
    }

    /**
     * Returns the latest price
     */
    function getAvaxLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getTokenPricePairedWithAvax(address token) public view returns (uint256 tokenPrice) {
        address factory = IAPRHelper(aprHelper).factory();
        if (token == wavax) {
            return getAvaxLatestPrice();
        }
        if (token == yyAvax) {
            return (IyyAvax(yyAvax).pricePerShare() * getAvaxLatestPrice()) / 1e18;
        }
        address joePair = IJoeFactory(factory).getPair(token, wavax);
        if (joePair == address(0)) {
            return 0;
        }
        (uint256 token0Amount, uint256 token1Amount, ) = IJoePair(joePair).getReserves();
        bool isAvaxToken0 = wavax < token;
        if (
            (isAvaxToken0 && token0Amount / 1e18 < 1) || (!isAvaxToken0 && token1Amount / 1e18 < 1)
        ) {
            return 0;
        }
        uint256 avaxAmount = isAvaxToken0 ? token0Amount : token1Amount;
        uint256 tokenAmount = isAvaxToken0 ? token1Amount : token0Amount;
        tokenPrice = ((avaxAmount * getAvaxLatestPrice() * 10**ERC20(token).decimals()) /
            (tokenAmount * 10**ERC20(wavax).decimals()));
    }

    function getJoeLPPrice(address lp) public view returns (uint256 inUSD) {
        address token0 = IJoePair(lp).token0();
        address token1 = IJoePair(lp).token1();
        uint256 token0Price = getTokenPricePairedWithAvax(token0);
        uint256 token1Price = getTokenPricePairedWithAvax(token1);
        token1Price = token1Price == 0
            ? ((token0Price * getRatio(token1, token0, 8)) / 10**8)
            : token1Price;
        token0Price = token0Price == 0
            ? ((token1Price * getRatio(token0, token1, 8)) / 10**8)
            : token0Price;
        uint256 totalSupply = IJoePair(lp).totalSupply();
        uint256 token0Amount = ERC20(token0).balanceOf(lp);
        uint256 token1Amount = ERC20(token1).balanceOf(lp);
        inUSD =
            ((((token0Amount * token0Price) / 10**ERC20(token0).decimals()) +
                ((token1Amount * token1Price) / 10**ERC20(token1).decimals())) *
                10**ERC20(lp).decimals()) /
            totalSupply;
    }

    function getAllowances(address user, address pool)
        public
        view
        returns (uint256 allowanceAmount)
    {
        address mainStaking = IAPRHelper(aprHelper).mainstakingTJ();
        (, , , , , address helper) = IMainStakingJoe(mainStaking).getPoolInfo(
            pool
        );
        allowanceAmount = IERC20(pool).allowance(user, helper);
    }

    function getJoeLPsPrices(address[] calldata lps) public view returns (uint256[] memory inUSD) {
        uint256 length = lps.length;
        inUSD = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            inUSD[i] = getJoeLPPrice(lps[i]);
        }
    }

    function getTokenPricePairedWithStable(address token, address stable)
        public
        view
        returns (uint256 tokenPrice)
    {
        address factory = IAPRHelper(aprHelper).factory();
        address joePair = IJoeFactory(factory).getPair(token, stable);
        if (joePair == address(0)) {
            return 0;
        }
        (uint256 token0Amount, uint256 token1Amount, ) = IJoePair(joePair).getReserves();
        bool isStableToken0 = stable < token;
        if (
            (isStableToken0 && token0Amount / 10**ERC20(stable).decimals() < 1) ||
            (!isStableToken0 && token1Amount / 10**ERC20(stable).decimals() < 1)
        ) {
            return 0;
        }
        uint256 stableAmount = isStableToken0 ? token0Amount : token1Amount;
        uint256 tokenAmount = isStableToken0 ? token1Amount : token0Amount;
        tokenPrice = ((stableAmount * (10**8) * 10**ERC20(token).decimals()) /
            (tokenAmount * 10**ERC20(stable).decimals()));
    }

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) public view returns (uint256 ratio) {
        address factory = IAPRHelper(aprHelper).factory();
        address joePair = IJoeFactory(factory).getPair(numerator, denominator);
        (uint256 tokenAmount0, uint256 tokenAmount1, ) = IJoePair(joePair).getReserves();
        return
            (numerator < denominator)
                ? ((tokenAmount1 * 10**(decimals) * 10**ERC20(numerator).decimals()) /
                    (tokenAmount0 * 10**ERC20(denominator).decimals()))
                : ((tokenAmount0 * 10**(decimals) * 10**ERC20(numerator).decimals()) /
                    (tokenAmount1 * 10**ERC20(denominator).decimals()));
    }

    function getTVLForLocker() public view returns (uint256 lockerTVL) {
        address locker = IAPRHelper(aprHelper).locker();
        address vtx = IAPRHelper(aprHelper).vtx();
        lockerTVL =
            (ILockerV2(locker).totalSupply() * getTokenPricePairedWithAvax(vtx)) /
            (10**ERC20(locker).decimals());
        lockerTVL = (lockerTVL == 0) ? 1 : lockerTVL;
    }

    function getVTXAPRForLocker() public view returns (uint256 APR) {
        address masterChief = IAPRHelper(aprHelper).masterChief();
        address locker = IAPRHelper(aprHelper).locker();
        address vtx = IAPRHelper(aprHelper).vtx();
        (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        ) = IMasterChefVTX(masterChief).getPoolInfo(ILockerV2(locker).stakingToken());
        uint256 VTXPerYear = (emission * 365 * 24 * 3600 * allocpoint) / totalPoint;
        APR = (VTXPerYear * getTokenPricePairedWithAvax(vtx)) / getTVLForLocker() / 10**8;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity ^0.8.0;

interface IJoePair {
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
pragma solidity 0.8.7;

interface IVoter {
    function add(
        address _gauge,
        address _lpToken,
        address _bribe
    ) external;

    function bribes(address) external view returns (address);

    function claimBribes(address[] calldata _lpTokens)
        external
        returns (uint256[] memory bribeRewards);

    function distribute(address _lpToken) external;

    function emergencyPtpWithdraw() external;

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function index() external view returns (uint128);

    function initialize(
        address _ptp,
        address _vePtp,
        uint88 _ptpPerSec,
        uint256 _startTimestamp
    ) external;

    function lastRewardTimestamp() external view returns (uint40);

    function lpTokenLength() external view returns (uint256);

    function lpTokens(uint256) external view returns (address);

    function owner() external view returns (address);

    function pause(address _lpToken) external;

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards);

    function pendingPtp(address _lpToken) external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPerSec() external view returns (uint88);

    function renounceOwnership() external;

    function resume(address _lpToken) external;

    function setBribe(address _lpToken, address _bribe) external;

    function setGauge(address _lpToken, address _gauge) external;

    function setPtpPerSec(uint88 _ptpPerSec) external;

    function totalWeight() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vePtp() external view returns (address);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[] memory bribeRewards);

    function votes(address, address) external view returns (uint256);

    function weights(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMasterChefVTX {
    event Add(uint256 allocPoint, address indexed lpToken, address indexed rewarder);
    event Deposit(address indexed user, address indexed lpToken, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed lpToken, uint256 amount);
    event Harvest(address indexed user, address indexed lpToken, uint256 amount);
    event Locked(address indexed user, address indexed lpToken, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Set(
        address indexed lpToken,
        uint256 allocPoint,
        address indexed rewarder,
        address indexed locker,
        bool overwrite
    );
    event Unlocked(address indexed user, address indexed lpToken, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 _vtxPerSec);
    event UpdatePool(
        address indexed lpToken,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accVTXPerShare
    );
    event Withdraw(address indexed user, address indexed lpToken, uint256 amount);

    function PoolManagers(address) external view returns (bool);

    function __MasterChefVTX_init(
        address _vtx,
        uint256 _vtxPerSec,
        uint256 _startTimestamp
    ) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function addressToPoolInfo(address)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accVTXPerShare,
            address rewarder,
            address helper,
            address locker
        );

    function allowEmergency() external;

    function authorizeForLock(address _address) external;

    function createRewarder(address _lpToken, address mainRewardToken) external returns (address);

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 availableAmount);

    function emergencyWithdraw(address _lp) external;

    function emergencyWithdrawWithReward(address _lp) external;

    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function isAuthorizedForLock(address) external view returns (bool);

    function massUpdatePools() external;

    function migrateEmergency(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrateToNewLocker(bool[] calldata onlyDeposit) external;

    function multiclaim(address[] calldata _lps, address user_address) external;

    function owner() external view returns (address);

    function pendingTokens(
        address _lp,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 pendingVTX,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolLength() external view returns (uint256);

    function realEmergencyWithdraw(address _lp) external;

    function registeredToken(uint256) external view returns (address);

    function renounceOwnership() external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function setPoolHelper(address _lp, address _helper) external;

    function setPoolManagerStatus(address _address, bool _bool) external;

    function setVtxLocker(address newLocker) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function updatePool(address _lp) external;

    function vtx() external view returns (address);

    function vtxLocker() external view returns (address);

    function vtxPerSec() external view returns (uint256);

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMainStaking {
    event AddFee(address to, uint256 value, bool isPTP, bool isAddress);
    event NewDeposit(address indexed user, address indexed token, uint256 amount);
    event NewPtpStaked(uint256 amount);
    event NewWithdraw(address indexed user, address indexed token, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PoolAdded(address tokenAddress);
    event PtpClaimed(uint256 amount);
    event PtpHarvested(uint256 amount, uint256 callerFee);
    event RemoveFee(address to);
    event RewardPaidTo(address to, address rewardToken, uint256 feeAmount);
    event SetFee(address to, uint256 value);

    function CALLER_FEE() external view returns (uint256);

    function MAX_CALLER_FEE() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function WAVAX() external view returns (address);

    function addBonusRewardForAsset(address _asset, address _bonusToken) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external;

    function assetToBonusRewards(address, uint256) external view returns (address);

    function bribeCallerFee() external view returns (uint256);

    function bribeFeeCollector() external view returns (address);

    function bribeManager() external view returns (address);

    function bribeProtocolFee() external view returns (uint256);

    function claimVePTP() external;

    function computeAPR() external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external;

    function depositWithDifferentAsset(
        address token,
        address asset,
        uint256 amount,
        address sender
    ) external;

    function feeInfos(uint256)
        external
        view
        returns (
            uint256 max_value,
            uint256 min_value,
            uint256 value,
            address to,
            bool isPTP,
            bool isAddress,
            bool isActive
        );

    function getDepositTokensForShares(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getLPTokensForShares(uint256 amount, address token) external view returns (uint256);

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        );

    function getSharesForDepositTokens(uint256 amount, address token)
        external
        view
        returns (uint256);

    function harvest(address token, bool isUser) external;

    function masterPlatypus() external view returns (address);

    function masterVtx() external view returns (address);

    function multiHarvest(address token, bool isUser) external;

    function owner() external view returns (address);

    function pendingBribeCallerFee(address[] calldata pendingPools)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory callerFeeAmount);

    function percentPTPStored() external view returns (uint256);

    function pools(address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lpAddress,
            uint256 sizeLp,
            uint256 size,
            address receiptToken,
            address rewarder,
            address helper
        );

    function ptp() external view returns (address);

    function ptpMigration(uint256[] calldata _pids) external;

    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external;

    function registerPoolWithDifferentAsset(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _assetToken,
        address _staking,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external returns (address, address);

    function removeFee(uint256 index) external;

    function removePool(address token) external;

    function renounceOwnership() external;

    function sendTokenRewards(address _token, address _rewarder) external;

    function setBribeCallerFee(uint256 newValue) external;

    function setBribeFeeCollector(address _collector) external;

    function setBribeManager(address _manager) external;

    function setBribeProtocolFee(uint256 newValue) external;

    function setCallerFee(uint256 value) external;

    function setFee(uint256 index, uint256 value) external;

    function setFeeRecipient(
        uint256 index,
        address _to,
        bool _isPtp,
        bool _isAddress
    ) external;

    function setMasterPlatypus(address _masterPtp) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolToken(address _token, address pool) external;

    function setSmartConvertor(address _smartConvertor) external;

    function setVoter(address _voter) external;

    function smartConvertor() external view returns (address);

    function stakePTP(uint256 amount) external;

    function stakingStable() external view returns (address);

    function staking_ptp() external view returns (address);

    function storagePTP() external view returns (address);

    function tokenToAvaxPool(address) external view returns (address);

    function tokenToPool(address) external view returns (address);

    function totalFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[] memory rewardTokens, uint256[] memory feeAmounts);

    function voter() external view returns (address);

    function withdraw(
        address token,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function withdrawLP(
        address token,
        uint256 _amount,
        address sender
    ) external;

    function withdrawWithDifferentAsset(
        address token,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function xPTP() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IBoostedMultiRewarder {
    function dilutingRepartition() external view returns (uint256);

    struct PoolInfo {
        address rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth. Times 1e12
        uint128 accTokenPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share. Time 1e12
    }

    function poolInfo(uint256 i)
        external
        view
        returns (
            address rewardToken, // Address of LP token contract.
            uint96 tokenPerSec, // How many base allocation points assigned to this pool
            uint128 accTokenPerShare, // Last timestamp that PTPs distribution occurs.
            uint128 accTokenPerFactorShare
        );

    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external;

    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view returns (uint256[] memory rewards);

    function rewardToken() external view returns (address token);

    function tokenPerSec() external view returns (uint256);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterPlatypusv4 {
    // Info of each user.
    struct UserInfo {
        // 256 bit packed
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor; // non-dialuting factor = sqrt (lpAmount * vePtp.balanceOf())
        // 256 bit packed
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 claimablePtp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare + user.factor * pool.accPtpPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare`, `accPtpPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        address rewarder;
        uint128 sumOfFactors; // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
        uint128 accPtpPerShare; // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
        uint128 accPtpPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share
    }

    function getSumOfFactors(uint256) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolId(address) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function emergencyWithdraw(uint256 _pid) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;

    function dilutingRepartition() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );

    function userInfo(uint256 _pid, address _address)
        external
        view
        returns (
            uint128 amount,
            uint128 factor,
            uint128 rewardDebt,
            uint128 claimablePtp
        );

    function migrate(uint256[] calldata _pids) external;

    function poolInfo(uint256 i)
        external
        view
        returns (
            address lpToken,
            address rewarder,
            uint128 sumOfFactors,
            uint128 accPtpPerShare,
            uint128 accPtpPerFactorShare
        );
}

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribeManager {
    event AddPool(address indexed lp, address indexed rewarder);
    event AllVoteReset();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VoteReset(address indexed lp);

    function __BribeManager_init(
        address _voter,
        address _veptp,
        address _mainStaking,
        address _locker
    ) external;

    function addPool(
        address _lp,
        address _rewarder,
        string calldata _name
    ) external;

    function avaxZapper() external view returns (address);

    function castVotes(bool swapForAvax)
        external
        returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function castVotesAndHarvestBribes(address[] calldata lps, bool swapForAvax) external;

    function castVotesCooldown() external view returns (uint256);

    function clearPools() external;

    function getLvtxVoteForPools(address[] calldata lps)
        external
        view
        returns (uint256[] memory lvtxVotes);

    function getUserLocked(address _user) external view returns (uint256);

    function getUserVoteForPools(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function getVoteForLp(address lp) external view returns (uint256);

    function getVoteForLps(address[] calldata lps) external view returns (uint256[] memory votes);

    function harvestAllBribes(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function harvestBribe(address[] calldata lps) external;

    function harvestBribeFor(address[] calldata lps, address _for) external;

    function harvestSinglePool(address[] calldata _lps) external;

    function isPoolActive(address pool) external view returns (bool);

    function lastCastTimer() external view returns (uint256);

    function locker() external view returns (address);

    function lpTokenLength() external view returns (uint256);

    function mainStaking() external view returns (address);

    function owner() external view returns (address);

    function poolInfos(address)
        external
        view
        returns (
            address poolAddress,
            address rewarder,
            bool isActive,
            string memory name
        );

    function poolTotalVote(address) external view returns (uint256);

    function pools(uint256) external view returns (address);

    function previewAvaxAmountForHarvest(address[] calldata _lps) external view returns (uint256);

    function previewBribes(
        address lp,
        address[] calldata inputRewardTokens,
        address _for
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function remainingVotes() external view returns (uint256);

    function removePool(uint256 _index) external;

    function renounceOwnership() external;

    function routePairAddresses(address) external view returns (address);

    function setAvaxZapper(address newZapper) external;

    function setPoolRewarder(address _pool, address _rewarder) external;

    function setVoter(address _voter) external;

    function totalVotes() external view returns (uint256);

    function totalVtxInVote() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unvote(address _lp) external;

    function usedVote() external view returns (uint256);

    function userTotalVote(address) external view returns (uint256);

    function userVoteForPools(address, address) external view returns (uint256);

    function vePtp() external view returns (address);

    function veptpPerLockedVtx() external view returns (uint256);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function voteAndCast(
        address[] calldata _lps,
        int256[] calldata _deltas,
        bool swapForAvax
    ) external returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILockerV2 {
    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 unlockingStrategy;
        uint256 alreadyUnstaked;
        uint256 alreadyWithdrawn;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address indexed user, uint256 indexed timestamp);
    event NewDeposit(address indexed user, uint256 indexed timestamp, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event ResetSlot(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 slotIndex
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Unlock(address indexed user, uint256 indexed timestamp, uint256 amount);
    event UnlockStarts(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 strategyIndex
    );
    event Unpaused(address account);

    function DENOMINATOR() external view returns (uint256);

    function VTX() external view returns (address);

    function __LockerV2_init_(
        address _masterchief,
        uint256 _maxSlots,
        address _previousLocker,
        address _rewarder,
        address _stakingToken
    ) external;

    function addNewStrategy(
        uint256 _lockTime,
        uint256 _rewardPercent,
        uint256 _forfeitPercent,
        uint256 _instantUnstakePercent,
        bool _isLinear
    ) external;

    function addToUnlock(uint256 amount, uint256 slotIndex) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function cancelUnlock(uint256 slotIndex) external;

    function claim()
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function claimFor(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount) external;

    function depositFor(address _for, uint256 _amount) external;

    function getAllUserUnlocking(address _user)
        external
        view
        returns (UserUnlocking[] memory slots);

    function getUserNthSlot(address _user, uint256 n)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );

    function getUserRewardPercentage(address _user)
        external
        view
        returns (uint256 rewardPercentage);

    function getUserSlotLength(address _user) external view returns (uint256);

    function getUserTotalDeposit(address _user) external view returns (uint256);

    function harvest() external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchief() external view returns (address);

    function maxSlot() external view returns (uint256);

    function migrate(address user, bool[] calldata onlyDeposit) external;

    function migrateFor(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrated(address) external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function previousLocker() external view returns (address);

    function renounceOwnership() external;

    function rewarder() external view returns (address);

    function setBribeManager(address _address) external;

    function setMaxSlots(uint256 _maxDeposits) external;

    function setPreviousLocker(address _locker) external;

    function setStrategyStatus(uint256 strategyIndex, bool status) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function stakeInMasterChief() external;

    function stakingToken() external view returns (address);

    function startUnlock(
        uint256 strategyIndex,
        uint256 amount,
        uint256 slotIndex
    ) external;

    function symbol() external view returns (string memory);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalUnlocking() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function unlock(uint256 slotIndex) external;

    function unlockingStrategies(uint256)
        external
        view
        returns (
            uint256 unlockTime,
            uint256 forfeitPercent,
            uint256 rewardPercent,
            uint256 instantUnstakePercent,
            bool isLinear,
            bool isActive
        );

    function unpause() external;

    function userUnlocking(address) external view returns (uint256);

    function userUnlockings(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribe {
    function balance() external view returns (uint256);

    function emergencyWithdraw() external;

    function isNative() external view returns (bool);

    function lpToken() external view returns (address);

    function onVote(
        address _user,
        uint256 _lpAmount,
        uint256 originalTotalVotes
    ) external returns (uint256);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function pendingTokens(address _user) external view returns (uint256 pending);

    function poolInfo()
        external
        view
        returns (uint128 accTokenPerShare, uint48 lastRewardTimestamp);

    function renounceOwnership() external;

    function rewardToken() external view returns (address);

    function setOperator(address _operator) external;

    function setRewardRate(uint256 _tokenPerSec) external;

    function tokenPerSec() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool() external;

    function userInfo(address)
        external
        view
        returns (
            uint128 amount,
            uint128 rewardDebt,
            uint256 unpaidRewards
        );

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IyyAvax {
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAPRHelper {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function AvaxUSDDecimals() external view returns (uint256);

    function FEE_DENOMINATOR() external view returns (uint256);

    function __APRHelper_init(address _wavax, address _mainStaking) external;

    function addPTPPool(address lp) external;

    function addTJPool(address lp) external;

    function balanceHelper() external view returns (address);

    function bribeManager() external view returns (address);

    function factory() external view returns (address);

    function futureVePTPPerVotedVTX(uint256 amount) external view returns (uint256);

    function getAPRforLockerInAdditionalReward(address lp, uint256 feeAmount)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAPRforPTPPoolInAdditionalReward(address lp) external view returns (uint256 APR);

    function getAPRforPTPPoolInAdditionalRewardArray(address lp)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAPRforPTPPoolInPTP(address lp)
        external
        view
        returns (uint256 baseAPR, uint256 boostedAPR);

    function getAPRforVotingForLVTX(address lp) external view returns (uint256 APR);

    function getAPRforxPTPInAdditionalReward(address lp, uint256 feeAmount)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAdditionalRewardsInUSDPerYear(address lp)
        external
        view
        returns (uint256[] memory USDPerYear, address[] memory rewardTokens);

    function getAllPendingBribes(
        address user,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory allRewardTokens, uint256[] memory totalAmounts);

    function getAvaxLatestPrice() external view returns (uint256 price);

    function getBribes(address lp) external view returns (uint256 bribesPerYear);

    function getBribesPerAmount(address lp, uint256 vtxAmount)
        external
        view
        returns (uint256 bribesPerYear);

    function getFutureAPRforVotingForLVTX(
        address lp,
        uint256 newVotes,
        int256 delta
    ) external view returns (uint256 APR);

    function getFutureBribesPerAmount(
        address lp,
        uint256 vtxAmount,
        uint256 newVotes,
        int256 delta
    ) external view returns (uint256 bribesPerYear);

    function getJoeClaimableRewards(
        address lp,
        address[] calldata inputRewardTokens,
        address user
    )
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getJoeHarvestableRewards(address lp, address user)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getJoeLPPrice(address lp) external view returns (uint256 inUSD);

    function getJoeLPsPrices(address[] calldata lps) external view returns (uint256[] memory inUSD);

    function getLPPrice(address lp) external view returns (uint256 inUSD);

    function getLPsPrice(address[] calldata lps) external view returns (uint256[] memory inUSD);

    function getLengthPtpPools() external view returns (uint256 length);

    function getLengthTJPools() external view returns (uint256 length);

    function getMultipleAPRforLockerlsInAdditionalReward(
        uint256 feeAmount,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (uint256[] memory APRs, address[] memory rewardTokens);

    function getMultipleAPRforPTPPoolsInPTP(address[] calldata lp)
        external
        view
        returns (uint256[] memory baseAPR, uint256[] memory boostedAPR);

    function getPTPClaimableRewards(
        address lp,
        address[] calldata inputRewardTokens,
        address user
    )
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getPTPHarvestableRewards(address lp, address user)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getPTPperYear(address lp) external view returns (uint256 ptpPerYearPerToken);

    function getPTPperYearForVector(address lp)
        external
        view
        returns (uint256 pendingBasePtp, uint256 pendingBoostedPtp);

    function getPendingBribes(
        address user,
        address lp,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getPendingRewardsFromLocker(address user, address[] calldata inputRewardTokens)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function getTVL(address lp) external view returns (uint256 TVLinUSD);

    function getTVLForLocker() external view returns (uint256 lockerTVL);

    function getTVLOfVotedLocker() external view returns (uint256 votedLocker);

    function getTokenPricePairedWithAvax(address token) external view returns (uint256 tokenPrice);

    function getVTXAPRForLocker() external view returns (uint256 APR);

    function getXPTPAPRForLocker(uint256 feeAmount) external view returns (uint256 APR);

    function getXPTPTVL() external view returns (uint256 usdValue);

    function locker() external view returns (address);

    function lp2asset(address) external view returns (address);

    function lp2pid(address) external view returns (uint256);

    function mainStaking() external view returns (address);

    function mainstakingTJ() external view returns (address);

    function masterChief() external view returns (address);

    function masterPlatypus() external view returns (address);

    function owner() external view returns (address);

    function platypusHelper() external view returns (address);

    function pool2pid(address) external view returns (address);

    function pool2token(address) external view returns (address);

    function precision() external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPools(uint256) external view returns (address);

    function renounceOwnership() external;

    function setTraderJoeMainstaking(address _mainStakingTJ) external;

    function setbalanceHelper(address _balanceHelper) external;

    function setlp2asset(address lp, address asset) external;

    function setplatypusHelper(address _platypusHelper) external;

    function setpool2token(address lp, address token) external;

    function settraderJoeHelper(address _traderJoeHelper) external;

    function tjPools(uint256) external view returns (address);

    function traderJoeHelper() external view returns (address);

    function transferOwnership(address newOwner) external;

    function vePTPPerVotedVTX() external view returns (uint256);

    function voter() external view returns (address);

    function vtx() external view returns (address);

    function wavax() external view returns (address);

    function xPTP() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBaseRewardPool {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address _account) external view returns (uint256);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function getReward(address _account) external returns (bool);

    function getRewardUser() external returns (bool);

    function getStakingToken() external view returns (address);

    function isRewardToken(address) external view returns (bool);

    function mainRewardToken() external view returns (address);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function renounceOwnership() external;

    function rewardDecimals(address _rewardToken) external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingDecimals() external view returns (uint256);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFor(address _account) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external returns (bool);
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
pragma solidity 0.8.7;

interface IMainStakingJoe {
    event AddFee(address to, uint256 value, bool isJoe, bool isAddress);
    event JoeHarvested(uint256 amount, uint256 callerFee);
    event MasterChiefSet(address _token);
    event MasterJoeSet(address _token);
    event NewJoeStaked(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PoolAdded(address tokenAddress);
    event PoolHelperSet(address _token);
    event PoolRemoved(address _token);
    event PoolRewarderSet(address token, address _poolRewarder);
    event RemoveFee(address to);
    event RewardPaidTo(address to, address rewardToken, uint256 feeAmount);
    event SetFee(address to, uint256 value);
    event veJoeClaimed(uint256 amount);

    function CALLER_FEE() external view returns (uint256);

    function MAX_CALLER_FEE() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function WAVAX() external view returns (address);

    function __MainStakingJoe_init(
        address _joe,
        address _boostedMasterChefJoe,
        address _masterVtx,
        address _veJoe,
        address _router,
        address _stakingJoe,
        uint256 _callerFee
    ) external;

    function addBonusRewardForAsset(address _asset, address _bonusToken) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isJoe,
        bool isAddress
    ) external;

    function assetToBonusRewards(address, uint256) external view returns (address);

    function boostBufferActivated() external view returns (bool);

    function boostEndDate() external view returns (uint256 date);

    function boosterThreshold() external view returns (uint256);

    function bypassBoostWait() external view returns (bool);

    function claimVeJoe() external;

    function deposit(address token, uint256 amount) external;

    function donateTokenRewards(address _token, address _rewarder) external;

    function feeInfos(uint256)
        external
        view
        returns (
            uint256 maxValue,
            uint256 minValue,
            uint256 value,
            address to,
            bool isJoe,
            bool isAddress,
            bool isActive
        );

    function getPendingVeJoe() external view returns (uint256 pending);

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receipt,
            address rewardsAddr,
            address helper
        );

    function getStakedJoe() external view returns (uint256 stakedJoe);

    function getVeJoe() external view returns (uint256);

    function harvest(address token, bool isUser) external;

    function joe() external view returns (address);

    function joeBalance() external view returns (uint256);

    function masterJoe() external view returns (address);

    function masterVtx() external view returns (address);

    function owner() external view returns (address);

    function pools(address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receiptToken,
            address rewarder,
            address helper
        );

    function registerPool(
        uint256 _pid,
        address _token,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external;

    function remainingForBoost() external view returns (uint256);

    function removeFee(uint256 index) external;

    function removePool(address token) external;

    function renounceOwnership() external;

    function router() external view returns (address);

    function sendTokenRewards(address _token, address _rewarder) external;

    function setBufferStatus(bool status) external;

    function setBypassBoostWait(bool status) external;

    function setCallerFee(uint256 value) external;

    function setFee(uint256 index, uint256 value) external;

    function setMasterChief(address _masterVtx) external;

    function setMasterJoe(address _masterJoe) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolRewarder(address token, address _poolRewarder) external;

    function setSmartConvertor(address _smartConvertor) external;

    function setXJoe(address _xJoe) external;

    function smartConvertor() external view returns (address);

    function stakeJoe(uint256 _amount) external;

    function stakeJoeOwner(uint256 _amount) external;

    function stakingJoe() external view returns (address);

    function tokenToAvaxPool(address) external view returns (address);

    function totalFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function veJoe() external view returns (address);

    function withdraw(address token, uint256 _amount) external;

    function xJoe() external view returns (address);
}