/**
 *Submitted for verification at snowtrace.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

/**
 * @dev Implementation of the {IERC20.sol} interface.
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
 * allowances. See {IERC20.sol-approve}.
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
     * {IERC20.sol-balanceOf} and {IERC20.sol-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20.sol-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20.sol-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20.sol-transfer}.
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
     * @dev See {IERC20.sol-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20.sol-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
     * @dev See {IERC20.sol-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }

_transfer(sender, recipient, amount);

return true;
}

/**
 * @dev Atomically increases the allowance granted to `spender` by the caller.
 *
 * This is an alternative to {approve} that can be used as a mitigation for
 * problems described in {IERC20.sol-approve}.
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
 * problems described in {IERC20.sol-approve}.
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

interface IPair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

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


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


contract ExposureBasket is ERC20, Ownable {

    mapping(uint256 => mapping(address => uint256)) private _tokenPortions;
    mapping(uint256 => mapping(address => address)) public _tokenMarkets;
    mapping(uint256 => mapping(address => uint256)) private _tokenMarketCaps;
    mapping(uint256 => mapping(address => uint256)) private _tokenPrices;
    mapping(uint256 => mapping(address => uint256)) private _tokenBuyAmount;
    mapping(uint256 => mapping(address => uint256)) private _tokenSellAmount;
    mapping(uint256 => mapping(address => uint256)) public _tokenWeights;
    mapping(uint256 => uint256) _epochWavaxBalance;

    mapping(uint256 => address[]) private _tokensToAdd;
    mapping(uint256 => address[]) private _tokensToRemove;

    mapping(uint256 => address[]) private _tokensToLiquidate;
    mapping(uint256 => address[]) private _tokensToBuy;

    mapping(uint256 => address[]) public _tokens;
    mapping(uint256 => mapping(address => uint8)) private _tokenIndex;
    mapping(uint256 => uint256) private indexPrice0;
    mapping(uint256 => uint256) private indexPrice1;

    mapping(uint256 => uint256) private indexDivisor;

    uint256 public _tokenCount;
    uint256 public epoch;
    uint8 public rebalanceStep;
    uint8 private rebalanceTokenIndex;

    uint256 public rebaseTimestamp;

    address public wavax;
    address public usdc;
    address public UNISWAP_V2_ROUTER;
    address public wavax_usd_pair;


    bool public isLive;
    //not needed can do step == 0
    //    bool public isRebase;
    bool public isRedeemableOnly;

    uint256 public revenueFee;
    address public feeContract;

    uint256 public basketCap;
    uint256 public slippageFactor;
    uint256 public epochTimeLimit;

    // Redundant, ERC20 already emits transfer to/from 0 address for mint/burn
    event ETF_Exchange(address indexed from, address[] tokens, uint256[] amounts, uint256[] fees);

    constructor (string memory name_, string memory symbol_, address router, address _wavax
    , address _wavax_usd_pair, address _usdc, address _owner) ERC20(name_, symbol_) {
        revenueFee = 30;
        basketCap = 10 * 1e18;
        //10 shares
        slippageFactor = 150;
        //1.5%
        epochTimeLimit = 60;
        // 10 minutes

        transferOwnership(_owner);
        feeContract = _owner;

        UNISWAP_V2_ROUTER = router;
        wavax = _wavax;
        wavax_usd_pair = _wavax_usd_pair;
        usdc = _usdc;
        indexDivisor[epoch] = 100000000 * 1e18;
    }

    function mint(uint256 amount, address to) external {
        require(isLive);
        require(rebalanceStep == 0);
        require(!isRedeemableOnly);
        require(!isOverCap(amount));
        uint256[] memory _amounts = new uint256[](_tokens[epoch].length);
        uint256[] memory _fees = new uint256[](_tokens[epoch].length);
        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            uint256 tokenAmount = (_tokenPortions[epoch][_tokens[epoch][i]] * (amount)) / 1e18;
            uint256 _fee = fee(tokenAmount, revenueFee);
            tokenAmount -= _fee;
            IERC20(_tokens[epoch][i]).transferFrom(msg.sender, feeContract, _fee);
            IERC20(_tokens[epoch][i]).transferFrom(msg.sender, address(this), tokenAmount);
            _amounts[i] = tokenAmount;
            _fees[i] = _fee;
        }
        emit ETF_Exchange(to, _tokens[epoch], _amounts, _fees);
        amount -= fee(amount, revenueFee);
        _mint(to, amount);
    }

    function burn(uint256 amount, address to) external {
        require(isLive);
        require(rebalanceStep == 0);
        _burn(to, amount);

        uint256[] memory _amounts = new uint256[](_tokens[epoch].length);
        uint256[] memory _fees = new uint256[](_tokens[epoch].length);
        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            uint256 tokenAmount = (_tokenPortions[epoch][_tokens[epoch][i]] * (amount)) / 1e18;
            uint256 _fee = fee(tokenAmount, revenueFee);
            tokenAmount -= _fee;
            IERC20(_tokens[epoch][i]).transfer(feeContract, _fee);
            IERC20(_tokens[epoch][i]).transfer(to, tokenAmount);
            _amounts[i] = tokenAmount;
            _fees[i] = _fee;
        }
        emit ETF_Exchange(to, _tokens[epoch], _amounts, _fees);
    }

    function startETF() public onlyOwner {
        require(!isLive, "ETF is not live.");
        require(rebalanceStep == 0, "Rebalance Step is not 0.");
        rebalanceStep = 1;
    }

    function initETF() public onlyOwner {
        require(!isLive);
        require(_tokens[epoch].length > 0);
        isLive = true;
        rebalanceStep = 0;
        _tokens[epoch + 1] = _tokens[epoch];
        indexDivisor[epoch + 1] = indexDivisor[epoch];
    }

    function batchStartBasket(address[] memory tokens, address[] memory tokenMarkets, address[] memory _removeTokens) public {
        startETF();
        stepsBatchOneOne(tokens, tokenMarkets, _removeTokens);
        stepsBatchOneTwo();
        initETF();
    }

    function stepsBatchOneOne(address[] memory tokens, address[] memory tokenMarkets, address[] memory _removeTokens) public onlyOwner {
        if (isLive)
            startRebalance();
        addTokens(tokens, tokenMarkets);
        removeTokens(_removeTokens);
        for (uint i = 0; i < tokens.length; i++)
        {
            updateTokenMarketCap();
        }
        updateIndexTotal();
        for (uint i = 0; i < tokens.length; i++)
        {
            updateTokenPortions();
        }
        updateRemainingPortions();
    }

    function stepsBatchOneTwo() public onlyOwner {
        rebaseLiquidate();
        rebaseBuy();
        finalizeIndexPrice();
        if (isLive)
            newEpoch();
    }

    function startRebalance() public {
        require(rebalanceStep == 0, "Rebalance Step is not 0.");
        require(block.timestamp >= rebaseTimestamp + epochTimeLimit);
        _tokens[epoch + 1] = _tokens[epoch];
        rebaseTimestamp = block.timestamp;
        epoch++;
        rebalanceStep = 1;
    }

    function addTokens(address[] memory tokens, address[] memory tokenMarkets) public {
        require(tokens.length == tokenMarkets.length, "Tokens length is not equal to Token Markets length");
        require(rebalanceStep == 1, "Rebalance Step is not 1.");

        for (uint8 i = 0; i < tokens.length; i++)
        {
            if (epoch > 0)
                _tokensToAdd[epoch].push(tokens[i]);

            _tokens[epoch] = tokens;
            _tokenMarkets[epoch][tokens[i]] = tokenMarkets[i];
            _tokenIndex[epoch][tokens[i]] = i;
        }

        _tokenCount = tokens.length;
        rebalanceStep = 2;
    }

    function removeTokens(address[] memory tokens) public {
        require(rebalanceStep == 2, "Rebalance Step is not 2.");

        for (uint8 i = 0; i < tokens.length; i++)
        {
            _tokenSellAmount[epoch][tokens[i]] = IERC20(tokens[i]).balanceOf(address(this));
            _tokensToLiquidate[epoch].push(tokens[i]);
            _tokensToRemove[epoch].push(tokens[i]);
            _tokenCount--;
        }

        rebalanceStep = 3;
    }

    function updateTokenMarketCap() public {
        require(rebalanceStep == 3, "Rebalance Step is not 3.");
        address _token = _tokens[epoch][rebalanceTokenIndex];
        IERC20 token = IERC20(_token);
        updateTokenPrice(_token);
        uint256 token_supply = token.totalSupply();

        _tokenMarketCaps[epoch][_token] = ((_tokenPrices[epoch][_token]) * (token_supply)) / 1e18;
        _tokenIndex[epoch + 1][_token] = _tokenIndex[epoch][_token];

        rebalanceTokenIndex++;
        if (rebalanceTokenIndex == _tokens[epoch].length)
        {
            rebalanceStep = 4;
            rebalanceTokenIndex = 0;
        }
    }

    function updateIndexTotal() public {
        require(rebalanceStep == 4, "Rebalance Step is not 4.");
        uint256 index = 0;
        uint256 indexForWeight = 0;
        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            indexForWeight += _tokenMarketCaps[epoch][_tokens[epoch][i]];
        }

        if (epoch > 0)
        {
            index = calculateEndEpochIndex();
            indexPrice0[epoch] = index;
            indexPrice1[epoch - 1] = indexForWeight;
        } else {
            indexPrice0[epoch] = indexForWeight;
        }

        rebalanceStep = 5;
    }

    function updateTokenPortions() public {
        require(rebalanceStep == 5, "Rebalance Step is not 5.");
        address _token = _tokens[epoch][rebalanceTokenIndex];
        uint256 index = indexPrice0[epoch];
        uint256 indexForWeight = indexPrice0[epoch];

        if (epoch > 0)
        {
            indexForWeight = indexPrice1[epoch - 1];
        }

        updateTokenPrice(_token);

        uint256 indexDivised = ((index * 1e18) / indexDivisor[epoch]);
        uint256 tokenWeight = ((_tokenMarketCaps[epoch][_token] * 1e18) / indexForWeight);
        uint256 tokenPortion = (((((indexDivised) * tokenWeight))) / (_tokenPrices[epoch][_token]));
        _tokenPortions[epoch][_token] = tokenPortion;
        _tokenWeights[epoch][_token] = tokenWeight;

        if (epoch > 0) {
            if (_tokenPortions[epoch - 1][_token] <= _tokenPortions[epoch][_token])
            {
                uint256 amount = (_tokenPortions[epoch][_token] - _tokenPortions[epoch - 1][_token]);
                uint256 total_amount = (amount * totalSupply()) / 1e18;
                _tokensToBuy[epoch].push(_token);
                _tokenBuyAmount[epoch][_token] = total_amount - ((total_amount * slippageFactor) / 10000);
            }
        }
        rebalanceTokenIndex++;
        if (rebalanceTokenIndex == _tokens[epoch].length)
        {
            rebalanceStep = 6;
            rebalanceTokenIndex = 0;
        }
    }

    function updateRemainingPortions() public {
        require(rebalanceStep == 6, "Rebalance Step is not 6.");

        if (epoch == 0)
        {
            rebalanceStep = 7;
            return;
        }

        for (uint8 i = 0; i < _tokensToBuy[epoch].length; i++) {
            uint256 amountToBuy = _tokenBuyAmount[epoch][_tokensToBuy[epoch][i]];

            for (uint8 j = 0; j < _tokens[epoch].length; j++)
            {
                updateTokenPrice(_tokens[epoch][j]);

                uint256 extraPortionToSell = ((((amountToBuy) * _tokenWeights[epoch][_tokens[epoch][j]]) * (_tokenPrices[epoch][_tokensToBuy[epoch][i]])) / 1e18) / _tokenPrices[epoch][_tokens[epoch][j]];

                extraPortionToSell = extraPortionToSell - ((extraPortionToSell * 5) / 10000);

                if (_tokensToBuy[epoch][i] == _tokens[epoch][j])
                {
                    _tokenBuyAmount[epoch][_tokensToBuy[epoch][i]] = amountToBuy - extraPortionToSell;
                } else {
                    if (IERC20(_tokens[epoch][j]).balanceOf(address(this)) > extraPortionToSell)
                    {
                        _tokenSellAmount[epoch][_tokens[epoch][j]] += extraPortionToSell;
                        _tokensToLiquidate[epoch].push(_tokens[epoch][j]);
                    }
                }

            }
        }

        rebalanceStep = 7;
    }

    function rebaseLiquidate() public {
        require(rebalanceStep == 7, "Rebalance Step is not 7.");
        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            if (_tokenSellAmount[epoch][_tokens[epoch][i]] > 0) {
                liquidate(_tokens[epoch][i]);
            }
        }

        for (uint8 i = 0; i < _tokensToRemove[epoch].length; i++)
        {
            if (_tokenSellAmount[epoch][_tokensToRemove[epoch][i]] > 0) {
                liquidate(_tokensToRemove[epoch][i]);
            }
        }
        _epochWavaxBalance[epoch] = IERC20(wavax).balanceOf(address(this));
        rebalanceStep = 8;
    }

    function rebaseBuy() public {
        require(rebalanceStep == 8, "Rebalance Step is not 8.");

        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            if (_tokenBuyAmount[epoch][_tokens[epoch][i]] > 0)
            {
                purchase(_tokens[epoch][i]);
            }
        }
        rebalanceStep = 9;
    }

    function finalizeIndexPrice() public {
        require(rebalanceStep == 9, "Rebalance Step is not 9.");
        uint256 indexSum = 0;
        for (uint8 i = 0; i < _tokens[epoch].length; i++)
        {
            uint256 tokenPrice = _tokenPrices[epoch][_tokens[epoch][i]];
            uint256 tokenPortion = _tokenPortions[epoch][_tokens[epoch][i]];
            uint256 tokenMCAPPortion;
            if (tokenPrice > tokenPortion) {
                tokenMCAPPortion = tokenPortion * (tokenPrice / 1e18);
            } else {
                tokenMCAPPortion = tokenPrice * (tokenPortion / 1e18);
            }
            indexSum += tokenMCAPPortion;
        }
        indexPrice0[epoch] = (indexSum * indexDivisor[epoch]) / 1e18;
        rebalanceStep = 10;
    }

    function newEpoch() public {
        require(isLive);
        require(rebalanceStep == 10, "Rebalance Step is not 9.");
        rebalanceStep = 0;
        rebalanceTokenIndex = 0;
        indexDivisor[epoch + 1] = indexDivisor[epoch];
    }

    function updateTokenPrice(address _token) internal {
        address tokenPairAddress = _tokenMarkets[epoch][_token];
        if (tokenPairAddress == address(0))
        {
            tokenPairAddress = _tokenMarkets[epoch - 1][_token];
        }

        (uint p0, uint p1,) = IPair(tokenPairAddress).getReserves();
        address token0 = IPair(tokenPairAddress).token0();
        uint256 price;

        if (token0 != _token) {
            price = ((p0 * 1e18) / p1);
        } else {
            price = ((p1 * 1e18) / p0);
        }

        (uint p2, uint p3,) = IPair(wavax_usd_pair).getReserves();

        uint256 token_price_usd = (p2 * 1e36) / (p3 * 1e12) / 1e18;
   
        
        token_price_usd = (price * 1e18) / token_price_usd;

        _tokenPrices[epoch][_token] = token_price_usd;
        _tokenMarkets[epoch + 1][_token] = tokenPairAddress;
    }

    function liquidate(address _token) internal {
        require(epoch > 0);
        address[] memory path;

        path = new address[](2);
        path[0] = _token;
        path[1] = wavax;

        uint256 swapAmount = _tokenSellAmount[epoch][_token];
        swapAmount = (swapAmount - ((swapAmount * slippageFactor) / 10000));
        require(IERC20(_token).approve(UNISWAP_V2_ROUTER, swapAmount));

        uint256[] memory amountOutMins = IUniswapV2Router01(UNISWAP_V2_ROUTER).getAmountsOut(swapAmount, path);
        IUniswapV2Router01(UNISWAP_V2_ROUTER).swapExactTokensForTokens(swapAmount, amountOutMins[1], path, address(this), block.timestamp + 40 seconds);
        uint256 bal = (IERC20(_token).balanceOf(address(this)) * 1e18) / totalSupply();
        _tokenPortions[epoch][_token] = bal - ((bal * 10) / 10000);
    }

    function purchase(address _token) internal {
        require(epoch > 0);
        address[] memory path;
        path = new address[](2);
        path[0] = wavax;
        path[1] = _token;
        uint256 portionPer = 0;
        uint256 total_weight = 0;
        uint256[] memory amountIns;
        uint256 tokenWeight = _tokenWeights[epoch][_token];
        uint256 wavaxTobuy = _epochWavaxBalance[epoch];

        for (uint8 i = 0; i < _tokensToBuy[epoch].length; i++)
        {
            total_weight += _tokenWeights[epoch][_tokensToBuy[epoch][i]];
        }
        uint256 weightMissing = 1e18 - total_weight;

        if (total_weight > tokenWeight)
        {
            uint256 a = ((tokenWeight * 1e18) / total_weight);
            uint256 b = 1e18 - a;
            uint256 c = b * weightMissing / 1e18;
            portionPer = tokenWeight + c;
        } else {
            uint256 a = ((total_weight * 1e18) / tokenWeight);
            uint256 b = a * weightMissing / 1e18;
            portionPer = tokenWeight + b;
        }

        wavaxTobuy = ((wavaxTobuy * portionPer) / 1e18);
        wavaxTobuy = wavaxTobuy - ((wavaxTobuy * 5) / 10000);

        amountIns = IUniswapV2Router01(UNISWAP_V2_ROUTER).getAmountsOut(wavaxTobuy, path);

        if (IERC20(wavax).balanceOf(address(this)) >= amountIns[0])
        {
            require(IERC20(wavax).balanceOf(address(this)) > amountIns[0]);
            require(IERC20(wavax).approve(UNISWAP_V2_ROUTER, amountIns[0]));
            IUniswapV2Router01(UNISWAP_V2_ROUTER).swapExactTokensForTokens(amountIns[0], amountIns[1], path, address(this), block.timestamp + 40 seconds);

            uint256 bal = (IERC20(_token).balanceOf(address(this)) * 1e18) / totalSupply();
            _tokenPortions[epoch][_token] = bal - ((bal * 5) / 10000);
        }

    }

    function calculateEndEpochIndex() internal returns (uint256) {
        require(epoch > 0);
        uint256 _epoch = epoch - 1;
        uint256 nav_index = 0;
        for (uint8 i = 0; i < _tokens[_epoch].length; i++)
        {
            updateTokenPrice(_tokens[_epoch][i]);
            uint256 token_price_usd = _tokenPrices[epoch][_tokens[_epoch][i]];
            nav_index += (((token_price_usd) * (_tokenPortions[_epoch][_tokens[_epoch][i]])) * indexDivisor[_epoch] / 1e36);
        }
        return nav_index;
    }

    function drain(address[] memory _tokenList) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
        for (uint8 i = 0; i < _tokenList.length; i++) {
            uint256 amount = IERC20(_tokenList[i]).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_tokenList[i]).transfer(owner(), amount);
            }

        }
    }

    function isOverCap(uint256 amount) internal view returns (bool) {
        uint256 total_added = totalSupply() + amount;
        return (total_added > basketCap);
    }

    function setBasketCap(uint256 _cap) public onlyOwner {
        require(_cap > basketCap);
        basketCap = _cap;
    }

    function setSlippageFactor(uint256 _slippageFactor) public onlyOwner {
        slippageFactor = _slippageFactor;
    }

    function setEpochTimeLimit(uint256 _epochTimeLimit) public onlyOwner {
        epochTimeLimit = _epochTimeLimit;
    }

    function getBasketCap() external view returns (uint256)
    {
        return basketCap;
    }

    function getIndexPrice(uint256 _epoch) public view returns (uint256) {
        return (indexPrice0[_epoch] * 1e18) / indexDivisor[_epoch];
    }

    function changeUniswapRouter(address _router) public onlyOwner {
        UNISWAP_V2_ROUTER = _router;
    }

    function changeWavax(address _wavax) public onlyOwner {
        wavax = _wavax;
    }

    function changeWAVAXUSDC(address _wavax_pair) public onlyOwner {
        wavax_usd_pair = _wavax_pair;
    }

    function getTokenMarketCap(uint256 _epoch, address _token) external view returns (uint256)
    {
        return _tokenMarketCaps[_epoch][_token];
    }

    function getTokenPortions(uint256 _epoch, address _token) external view returns (uint256)
    {
        return _tokenPortions[_epoch][_token];
    }

    function getTokenPrice(uint256 _epoch, address _token) external view returns (uint256)
    {
        return _tokenPrices[_epoch][_token];
    }

    function getTokenBuyAmount(uint256 _epoch, address _token) external view returns (uint256)
    {
        return _tokenBuyAmount[_epoch][_token];
    }

    function getTokenSellAmount(uint256 _epoch, address _token) external view returns (uint256)
    {
        return _tokenSellAmount[_epoch][_token];
    }

    function fee(uint _value, uint256 feeType) internal pure returns (uint256) {
        return (_value * (feeType)) / (10000);
    }

}

contract ExposureFactory {
    event AssetBasketCreated(address tokenAddress);

    function deployNewAssetBasket(
        string memory name,
        string memory symbol,
        address router,
        address wavax,
        address wavax_usd_pair,
        address usdc,
        address owner
    ) public returns (address) {
        ExposureBasket t = new ExposureBasket(
            name, 
            symbol,
            router,
            wavax,
            wavax_usd_pair,
            usdc,
            owner
        );
        emit AssetBasketCreated(address(t));

        return address(t);
    }
}

interface IExposureBasket {
    function mint(uint256 amount, address to) external;
    function WETH() external pure returns (address);
    function getTokenPortions(uint256 _epoch, address _token) external view returns (uint256);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract AutoMint is Ownable {

    address wavax;
    address router;
    address[] tokens;
    address exposureAddress;

    // check if secondary market gets you more shares
    

    constructor(address _wavax, address _router, address _exposureAddress, address _owner) {
        wavax = _wavax;
        transferOwnership(_owner);
        router = _router;
        exposureAddress = _exposureAddress;
    }

    function CreateShares(address[] memory _tokenList, uint256 epoch) payable external {
        IExposureBasket exposure = IExposureBasket(exposureAddress);
        WAVAX(payable(wavax)).deposit{value: msg.value}();
        require(IERC20(wavax).balanceOf(address(this)) >= msg.value);
        
        uint256[] memory portions = new uint256[](_tokenList.length);
        uint256[] memory costs = new uint256[](_tokenList.length);
        address[] memory path = new address[](2);
        uint256 avaxCostForTokens;
        for (uint i; i < _tokenList.length; i++) {
            uint256 portion = exposure.getTokenPortions(epoch, _tokenList[i]);
            portions[i] = portion;
            path[0] = address(wavax);
            path[1] = _tokenList[i];
            uint[] memory amounts = IUniswapV2Router01(router).getAmountsIn(portion, path);
            avaxCostForTokens = avaxCostForTokens + amounts[0];
            costs[i] = amounts[0];
        }

        uint256 numberOfShares = (msg.value * 1e18 / avaxCostForTokens) * (9995 * 1e14) / 1e18;
        for (uint i; i < portions.length; i++) {
            IERC20(wavax).approve(router, costs[i] * numberOfShares / 1e18);
            path[0] = address(wavax);
            path[1] = _tokenList[i];
            IUniswapV2Router01(router).swapExactTokensForTokens(costs[i] * numberOfShares / 1e18, 1, path, address(this), block.timestamp + 40 seconds);
        }

        uint256 newShares = ~uint256(0);
        for (uint i; i < portions.length; i++) {
            uint256 bal = IERC20(_tokenList[i]).balanceOf(address(this));
            uint256 maxAmount = bal * 1e18 / portions[i];
            if (maxAmount < newShares)
                newShares = maxAmount;
        }

        for (uint i; i < portions.length; i++) {
            IERC20(_tokenList[i]).approve(exposureAddress, (portions[i] * newShares / 1e18) + 1);
        }
        newShares = newShares * (9995 * 1e14) / 1e18;
        exposure.mint(newShares, msg.sender);
    }

    function drain(address[] memory _tokenList) public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
        for (uint8 i = 0; i < _tokenList.length; i++) {
            uint256 amount = IERC20(_tokenList[i]).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_tokenList[i]).transfer(owner(), amount);
            }

        }
    }
}

contract WAVAX {
    string public name     = "Wrapped AVAX";
    string public symbol   = "WAVAX";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    // function transfer(address dst, uint wad) public returns (bool) {
    //     return transferFrom(msg.sender, dst, wad);
    // }

    // function transferFrom(address src, address dst, uint wad)
    //     public
    //     returns (bool)
    // {
    //     require(balanceOf[src] >= wad);

    //     if (src != msg.sender && allowance[src][msg.sender] != -1) {
    //         require(allowance[src][msg.sender] >= wad);
    //         allowance[src][msg.sender] -= wad;
    //     }

    //     balanceOf[src] -= wad;
    //     balanceOf[dst] += wad;

    //     emit Transfer(src, dst, wad);

    //     return true;
    // }
}