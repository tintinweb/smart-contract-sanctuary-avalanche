/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

interface IJoeRouter01 {
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

interface IJoeRouter02 is IJoeRouter01 {
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

// File contracts/IJoeFactory.sol

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


contract NodeRewardManagement{

    struct NodeEntity {
        uint256 nodeLevel;
        uint256 creationTime;
        uint256 lastClaimTime;
    }
    
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => uint256) public numberOfCapoNodes;
    mapping(address => uint256) public numberOfDonNodes;
	mapping(address => bool) public managers;

    uint256 public totalCapoNodesCreated = 0;
    uint256 public totalDonNodesCreated = 0;
    uint256 public maxCapoNodePerWallet = 30;
    uint256 public maxDonNodePerWallet = 2;
    uint256 public capoNodeQuantityToUpgrade = 20;

    uint256 public nodePrice;
    uint256 public rewardPerDayPerCapoNode;
    uint256 public rewardPerSecondPerCapoNode;
    uint256 public donMultiplier;

    constructor(uint256 nodePrice_, uint256 maxCapoNodePerWallet_, uint256 rewardPerDayPerCapoNode_, uint256 donMultiplier_) {
        nodePrice = nodePrice_ * 10 ** 18;
        maxCapoNodePerWallet = maxCapoNodePerWallet_;

        rewardPerDayPerCapoNode = rewardPerDayPerCapoNode_ * 10 ** 18;
        rewardPerSecondPerCapoNode = rewardPerDayPerCapoNode / 86400;

        donMultiplier = donMultiplier_;

        managers[msg.sender] = true;
    }

    /* UPDATE VARIABLES */

    modifier onlyManager(){
        require(managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    function addManager(address account) external onlyManager{
		managers[account] = true;
	}

    function updateCapoNodeQuantityToUpgrade(uint256 capoNodeQuantityToUpgrade_) external onlyManager{
        capoNodeQuantityToUpgrade = capoNodeQuantityToUpgrade_;
    }

    function updateNodes(uint256 nodePrice_, uint256 rewardPerDayPerCapoNode_, uint256 donMultiplier_) external onlyManager{
        nodePrice = nodePrice_ * 10 ** 18;

        rewardPerDayPerCapoNode = rewardPerDayPerCapoNode_ * 10 ** 18;
        rewardPerSecondPerCapoNode = rewardPerDayPerCapoNode / 86400;

        donMultiplier = donMultiplier_;
    }

    function updateMaxNodes(uint256 maxCapoNodePerWallet_, uint256 maxDonNodePerWallet_ ) external onlyManager{
        maxCapoNodePerWallet = maxCapoNodePerWallet_;
        maxDonNodePerWallet = maxDonNodePerWallet_;
    }

    /* FUNCTIONS */

    function createNode(address account_) external onlyManager{
        require(numberOfCapoNodes[account_] < maxCapoNodePerWallet, "NODE CREATION : You reached the max amount of node creation for your wallet");
        _nodesOfUser[account_].push(
            NodeEntity({
                nodeLevel: 0,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp
            })
        );
        numberOfCapoNodes[account_]++;
        totalCapoNodesCreated++;
    }

    function createMultiNodes(address account_, uint256 quantity) external onlyManager{
        require(numberOfCapoNodes[account_] + quantity <= maxCapoNodePerWallet, "NODE CREATION : You reached the max amount of node creation for your wallet");
        for(uint i=0; i < quantity;){
            _nodesOfUser[account_].push(
                NodeEntity({
                    nodeLevel: 0,
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp
                })
            );
            unchecked{i++;}
        }
        numberOfCapoNodes[account_] += quantity;
        totalCapoNodesCreated += quantity;
    }

    function cashoutAllNodesReward(address account_) external onlyManager{
        require(_nodesOfUser[account_].length > 0, "CASHOUT ERROR: You don't have nodes to cash-out");
        NodeEntity[] storage nodes = _nodesOfUser[account_];
        for(uint i=0; i<_nodesOfUser[account_].length;){
            NodeEntity storage node = nodes[i];
            node.lastClaimTime = block.timestamp;
            unchecked{i++;}
        }
    }

    function upgradeNodes(address account_) external onlyManager{
        require(numberOfDonNodes[account_] < maxDonNodePerWallet, "UPGRADE NODE: You have already reached the max amount of Don Nodes.");
        require(numberOfCapoNodes[account_] >= capoNodeQuantityToUpgrade, "UPGRADE NODE: You don't have enough Capo Nodes to upgrade.");

        uint i = 0;
        uint nodeRemovedCounter = 0;

        while(nodeRemovedCounter < capoNodeQuantityToUpgrade){
            if(_nodesOfUser[account_][i].nodeLevel == 0){
                removeWithIndex(account_, i);
                nodeRemovedCounter++;
                numberOfCapoNodes[account_]--;
            }
            else{
                i++;
            }
        }

        _nodesOfUser[account_].push(
            NodeEntity({
                nodeLevel: 1,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp
            })
        );
        numberOfDonNodes[account_]++;
        totalDonNodesCreated++;
    }

    function removeWithIndex(address account_, uint256 index) private {
        require(index < _nodesOfUser[account_].length);
        for(uint i = index; i < _nodesOfUser[account_].length - 1;){
            _nodesOfUser[account_][i] = _nodesOfUser[account_][i++];
            unchecked{i++;}
        }
        _nodesOfUser[account_].pop(); //pop functions deletes the last element of an array.
    }

    /* NODES DATA */

    function getAllNodesRewardAmount(address account_) public view returns(uint256){
        require(_nodesOfUser[account_].length > 0, "REWARD ERROR: You don't have nodes to cash-out");
        NodeEntity[] storage nodes = _nodesOfUser[account_];
        uint256 rewardAmount = 0;
        for(uint i=0; i<_nodesOfUser[account_].length;){
            NodeEntity storage node = nodes[i];
            if(node.nodeLevel == 1){
                rewardAmount += ((block.timestamp - node.lastClaimTime) * rewardPerSecondPerCapoNode) * donMultiplier;
            }
            else{
                rewardAmount += (block.timestamp - node.lastClaimTime) * rewardPerSecondPerCapoNode;
            }
            unchecked{i++;}
        }
        return rewardAmount;
    }

    function getCapoNodesRewardAmount(address account_) public view returns(uint256){
        if(numberOfCapoNodes[account_] == 0){
            return 0;
        }
        else{
            NodeEntity[] storage nodes = _nodesOfUser[account_];
            uint256 rewardAmount = 0;
            for(uint i=0; i<_nodesOfUser[account_].length;){
                NodeEntity storage node = nodes[i];
                if(node.nodeLevel == 0){
                    rewardAmount += (block.timestamp - node.lastClaimTime) * rewardPerSecondPerCapoNode;
                }
                unchecked{i++;}
            }
            return rewardAmount;
        }
    }

    function getDonNodesRewardAmount(address account_) public view returns(uint256){
        if(numberOfDonNodes[account_] == 0){
            return 0;
        }
        else{
            NodeEntity[] storage nodes = _nodesOfUser[account_];
            uint256 rewardAmount = 0;
            for(uint i=0; i<_nodesOfUser[account_].length;){
                NodeEntity storage node = nodes[i];
                if(node.nodeLevel == 1){
                    rewardAmount += ((block.timestamp - node.lastClaimTime) * rewardPerSecondPerCapoNode) * donMultiplier;
                }
                unchecked{i++;}
            }
            return rewardAmount;
        }
    }
}

contract MafiaNodes is Ownable, ERC20{

    IJoeRouter02 public joeRouter;
    address public joePair;

    NodeRewardManagement public nodeRewardManagement;

    string constant private _name = "EKIPAFONDDDDDDD";
    string constant private _symbol = "KZZ";
    uint256 private _totalSupply = 20_000_000 * 10 ** 18;

    uint256 private _maxTxAmount;
    uint256 private _maxWalletAmount;

    address public rewardPoolAddress;
    address public teamAddress;

    /* EVENTS */
    event createdNodeWithTokens(address indexed from);
    event createdMultipleNodesWithTokens(address indexed from, uint256 quantity);
    event airdroppedNodeToUser(address indexed to);
    event claimedNodeReward(address indexed from, uint rewardAmount);
    event claimedAllNodesReward(address indexed from, uint rewardAmount);
    event upgradedNodes(address indexed from);

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isFeeExcluded;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) private _isExcludedFromMaxWallet;
    mapping (address => bool) public isAutomatedMarketMakerPair;

    struct feeStruct{
        uint256 teamFee;
        uint256 rewardPoolFee;
        uint256 liquidityFee;
        uint256 burnFee;
        uint256 totalFee; //Fee applied to amount
    }

    feeStruct public sellFees = feeStruct({
        teamFee : 5000,
        rewardPoolFee : 0,
        liquidityFee : 5000,
        burnFee : 0,
        totalFee : 2000
    });

    feeStruct public mintFees = feeStruct({
        teamFee : 1000,
        rewardPoolFee : 5000,
        liquidityFee : 6000,
        burnFee : 1000,
        totalFee : 10000
    });

    feeStruct public claimFees = feeStruct({
        teamFee : 3340,
        rewardPoolFee : 6660,
        liquidityFee : 0,
        burnFee : 0,
        totalFee : 1500
    });

    feeStruct private appliedRates;
    uint256 public feeDenominator = 10000;

    /* CONSTRUCTOR */
    constructor(address[] memory addresses) ERC20(_name, _symbol){
        joeRouter = IJoeRouter02(0x7E3411B04766089cFaa52DB688855356A12f05D1); //Testnet 0x7E3411B04766089cFaa52DB688855356A12f05D1 - Main 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        joePair = IJoeFactory(joeRouter.factory()).createPair(address(this), joeRouter.WAVAX());
        isAutomatedMarketMakerPair[joePair] = true; 

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[teamAddress] = true;
        _isFeeExcluded[address(this)] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[teamAddress] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        teamAddress = addresses[0];
        rewardPoolAddress = addresses[1];

        _mint(msg.sender, _totalSupply);
        super._transfer(msg.sender, rewardPoolAddress, 19_000_000 * 10 ** 18);
    }

    /* UPDATE FEES FUNCTIONS */
    /* Fees needs to be set between (10000 = 100% >= fees >= 0 = 0%) */

    function updateSellFees(uint256 teamFee_, uint256 rewardPoolFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner{
        sellFees.teamFee = teamFee_;
        sellFees.rewardPoolFee = rewardPoolFee_;
        sellFees.liquidityFee = liquidityFee_;
        sellFees.burnFee = burnFee_;
        sellFees.totalFee = teamFee_ + rewardPoolFee_ + liquidityFee_ + burnFee_;
    }

    function updateMintFees(uint256 teamFee_, uint256 rewardPoolFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner{
        mintFees.teamFee = teamFee_;
        mintFees.rewardPoolFee = rewardPoolFee_;
        mintFees.liquidityFee = liquidityFee_;
        mintFees.burnFee = burnFee_;
        mintFees.totalFee = teamFee_ + rewardPoolFee_ + liquidityFee_ + burnFee_;
    }

    function updateClaimFees(uint256 teamFee_, uint256 rewardPoolFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner{
        claimFees.teamFee = teamFee_;
        claimFees.rewardPoolFee = rewardPoolFee_;
        claimFees.liquidityFee = liquidityFee_;
        claimFees.burnFee = burnFee_;
        claimFees.totalFee = teamFee_ + rewardPoolFee_ + liquidityFee_ + burnFee_;
    }

    /* UPDATE TX/WALLET RESTRICTIONS */
    
    function updateMaxTx(uint256 value) external onlyOwner {
        _maxTxAmount = value;
    }

    function updateMaxWallet(uint256 value) external onlyOwner {
        _maxWalletAmount = value;
    }

    /* EXCLUDE FROM FEES/BLACKLIST FUNCTIONS */

    function updateExcludeFromFeesStatus(address account, bool status) external onlyOwner{
        _isFeeExcluded[account] = status;
    }

    function updateBlacklistedStatus(address account, bool status) external onlyOwner{
        _isBlacklisted[account] = status;
    }

    function updateExcludedFromMaxWalletStatus(address account, bool status) external onlyOwner{
        _isExcludedFromMaxWallet[account] = status;
    }

    function setNodeManagement(address nodeManager) external onlyOwner {
        nodeRewardManagement = NodeRewardManagement(nodeManager);
    }

    /* PUBLIC FUNCTIONS TO CHECK STATUS */

    function isExcludedFromFees(address account) public view returns (bool){
        return _isFeeExcluded[account];
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool){
        return _isExcludedFromMaxWallet[account];
    }

    function isBlacklisted(address account) public view returns (bool){
        return _isBlacklisted[account];
    }

    /* TRANSFER FUNCTIONS */
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(!_isBlacklisted[from], "ERC20: From Blacklisted address");
        require(!_isBlacklisted[to], "ERC20: To Blacklisted address");
        uint remainingAmount = amount;

        /* if (!isAutomatedMarketMakerPair[from] && !_isFeeExcluded[to]){
            //Sell operation
            uint taxAmount = amount * (appliedRates.totalFee / feeDenominator);
            remainingAmount = amount - taxAmount;
            super._transfer(from, address(this), taxAmount);
            swapAndSendToAddress(teamAddress, taxAmount * (sellFees.teamFee / feeDenominator));
            swapAndLiquify(taxAmount * (sellFees.liquidityFee / feeDenominator));
        }    */

        super._transfer(from, to, remainingAmount);
    }

    function createNodeWithTokens() public {
        address sender = msg.sender;
        require(!_isBlacklisted[sender], "User is blacklisted.");
        uint nodePrice = nodeRewardManagement.nodePrice();
        require(balanceOf(sender) >= nodePrice, "You don't have enough funs to create a node.");
        require(sender != address(0), "NODE CREATION:  creation from the zero address");

        /* if(!_isFeeExcluded[sender]){
            swapAndSendToAddress(teamAddress, nodePrice * (mintFees.teamFee / feeDenominator));
            super._transfer(address(this), rewardPoolAddress, nodePrice * (mintFees.rewardPoolFee / feeDenominator));
            swapAndLiquify(nodePrice * (mintFees.liquidityFee / feeDenominator));
            _burn(address(this), nodePrice * (mintFees.burnFee / feeDenominator));
        }  */
        nodeRewardManagement.createNode(sender);
        super._transfer(sender, address(this), nodePrice);
        emit createdNodeWithTokens(msg.sender);
    }

    function createMultipleNodesWithTokens(uint256 quantity) public {
        address sender = msg.sender;
        uint nodesPrice = nodeRewardManagement.nodePrice() * quantity;
        require(balanceOf(sender) >= nodesPrice, "You don't have enough funs to create a node.");
        require(sender != address(0), "NODE CREATION:  creation from the zero address");

        /* if(!_isFeeExcluded[sender]){
            swapAndSendToAddress(teamAddress, nodesPrice * (mintFees.teamFee / feeDenominator));
            super._transfer(address(this), rewardPoolAddress, nodesPrice * (mintFees.rewardPoolFee / feeDenominator));
            swapAndLiquify(nodesPrice * (mintFees.liquidityFee / feeDenominator));
            _burn(address(this), nodesPrice * (mintFees.burnFee / feeDenominator));
        }  */

        nodeRewardManagement.createMultiNodes(sender, quantity);
        super._transfer(sender, address(this), nodesPrice);
        emit createdMultipleNodesWithTokens(msg.sender, quantity);
    }

    function airdropNodeToUser(address account_) external onlyOwner{
        nodeRewardManagement.createNode(account_);
        emit airdroppedNodeToUser(account_);
    }

    function claimAllNodesReward() public {
        require(msg.sender != address(0), "Function called from address 0.");

        uint claimableRewards = nodeRewardManagement.getAllNodesRewardAmount(msg.sender);
        uint userClaimableRewards = claimableRewards;

        /* if(!_isFeeExcluded[msg.sender]){
            userClaimableRewards = claimableRewards * (1 - (claimFees.totalFee / feeDenominator));
            uint feeClaimableRewards = claimableRewards - userClaimableRewards;
            uint teamFee = feeClaimableRewards * (claimFees.teamFee / feeDenominator);
            super._transfer(rewardPoolAddress, address(this), teamFee);
            swapAndSendToAddress(teamAddress, teamFee);
        } */

        nodeRewardManagement.cashoutAllNodesReward(msg.sender);
        super._transfer(msg.sender, rewardPoolAddress, userClaimableRewards);
        emit claimedAllNodesReward(msg.sender, claimableRewards);
    }

    function upgradeNodes() public {
        require(msg.sender != address(0), "Function called from address 0.");
        
        nodeRewardManagement.upgradeNodes(msg.sender);
        emit upgradedNodes(msg.sender);
    }

    function swapAndSendToAddress(address account, uint256 amount) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForAVAX(amount);
        uint256 deltaBalance = address(this).balance - initialBalance;
        (bool success,) = payable(account).call{value: deltaBalance}("");
        require(success, "Error sending the AVAXs");
    }

    function swapAndLiquify(uint256 amount) private {
        uint amountToSwap = amount / 2;
        uint amountToken = amount - amountToSwap;
        uint initialBalance = address(this).balance;

        swapTokensForAVAX(amountToSwap);

        uint deltaBalance = address(this).balance - initialBalance;

        _addLiquidity(amountToken, deltaBalance);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(isAutomatedMarketMakerPair[pair] != value, "This pair is already defined as an automated market maker pair.");
        isAutomatedMarketMakerPair[pair] = value;
    }

    /* BASIC TRADER JOE ROUTER FUNCTIONS */

    function _addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(joeRouter), tokenAmount);

        // add the liquidity
        joeRouter.addLiquidityAVAX{value: avaxAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function swapTokensForAVAX(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();

        _approve(address(this), address(joeRouter), tokenAmount);

        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp
        );
    }

    function nodesData() public view returns(uint256 capoNodePrice, uint256 donNodePrice, uint256 rewardPerDayPerCapoNode, uint256 rewardPerDayPerDonNode){
        capoNodePrice = nodeRewardManagement.nodePrice();
        donNodePrice = nodeRewardManagement.capoNodeQuantityToUpgrade();
        rewardPerDayPerCapoNode = nodeRewardManagement.rewardPerDayPerCapoNode();
        rewardPerDayPerDonNode = rewardPerDayPerCapoNode * nodeRewardManagement.donMultiplier();

        return (capoNodePrice, donNodePrice, rewardPerDayPerCapoNode, rewardPerDayPerDonNode);
    }

    function userData() public view returns(uint256 capoNodesOwned, uint256 donNodesOwned, uint256 capoNodesRewardAmount, uint256 donNodesRewardAmount){
       capoNodesOwned = nodeRewardManagement.numberOfCapoNodes(msg.sender);
       donNodesOwned = nodeRewardManagement.numberOfDonNodes(msg.sender);
       capoNodesRewardAmount = nodeRewardManagement.getCapoNodesRewardAmount(msg.sender);
       donNodesRewardAmount = nodeRewardManagement.getDonNodesRewardAmount(msg.sender);

       return (capoNodesOwned, donNodesOwned, capoNodesRewardAmount, donNodesRewardAmount);
    }
}