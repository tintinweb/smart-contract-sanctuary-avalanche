/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-09
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File multisol-cablesmaster/Context.sol


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


// File multisol-cablesmaster/IERC20.sol


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


// File multisol-cablesmaster/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File multisol-cablesmaster/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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


// File multisol-cablesmaster/ExecutionFacility.sol


pragma solidity ^0.8.17;

enum ExecutionFacility {
    Nexus,
    Coinbase,
    Binance
}


// File multisol-cablesmaster/OrderStatus.sol


pragma solidity ^0.8.17;

enum OrderStatus {
    OpenUnfilled,
    OpenPartiallyFilled,
    ClosedPartiallyFilled,
    ClosedFullyFilled,
    ClosedCanceled
}


// File multisol-cablesmaster/OrderType.sol


pragma solidity ^0.8.17;

enum OrderType {
    Sell,
    Buy
}


// File multisol-cablesmaster/TradeType.sol


pragma solidity ^0.8.17;

enum TradeType {
    Limit,
    Market
}


// File multisol-cablesmaster/Order.sol


pragma solidity ^0.8.17;




struct Order {
    address creator;

    OrderType orderType;
    TradeType tradeType;

    address baseCurrency;
    address quoteCurrency;

    uint baseAmount;
    uint quoteAmount;

    uint limitPrice;

    ExecutionFacility executionFacility;

    uint gasDeposit;

    uint slippage;

    OrderStatus status;
}


// File multisol-cablesmaster/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File multisol-cablesmaster/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File multisol-cablesmaster/CablesEscrow.sol


pragma solidity ^0.8.17;







/**
* @title Cables escrow contract
 **/
contract CablesEscrow is Ownable, ReentrancyGuard {
    // the address used to identify AVAX
    address constant AVAX_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public feeReceiver;

    uint constant FEE_DECIMALS = 1;
    uint public feePortion = 2; // 0.2%

    uint public basicGasDeposit;
    address public master;
    uint public escrowCount;

    mapping(address => uint) executionFacilities;

    mapping(uint => Escrow) public escrows;

    // list of open escrow ids of the user
    mapping(address => uint[]) public usersOpenEscrowsIds;
    // list of close escrow ids of the user
    mapping(address => uint[]) public usersCloseEscrowsIds;

    // filtered list of open escrow ids
    // filteredOpenEscrowsIds[orderType][baseCurrency][quoteCurrency]
    mapping(OrderType => mapping(address => mapping(address => uint[]))) public filteredOpenEscrowsIds;

    mapping(uint => OrderChange[]) orderChanges;

    struct Escrow {
        address user;
        uint balance;

        Order order;
    }

    struct StatusChange {
        uint timestamp;
        OrderStatus newStatus;
    }

    struct OrderChange {
        uint timestamp;
        OrderStatus newStatus;
        uint quantityFilled;
        uint totalQuantityFilled;
        uint priceFilledAt;
        uint averagePrice;
    }

    /**
    * @dev emitted when `owner` sets CablesMaster contract
    * @param _cablesMaster the address of the CablesMaster contract
    * @param _timestamp the timestamp of the action
    **/
    event SetMaster(
        address indexed _cablesMaster,
        uint _timestamp
    );

    /**
    * @dev emitted when `owner` changes fee portion
    * @param _feePortion new fee portion
    * @param _timestamp the timestamp of the action
    **/
    event SetFeePortion(
        uint _feePortion,
        uint _timestamp
    );

    constructor (address _feeReceiver) {
        require(_feeReceiver != address(0), '_feeReceiver is address(0)');

        feeReceiver = _feeReceiver;
        basicGasDeposit = 0.03 ether;
    }

    modifier onlyMaster() {
        require(msg.sender == master, "Not master");
        _;
    }

    modifier onlyExecutionFacility() {
        require(isExecutionFacility(msg.sender) == true, "Not Execution Facility");

        _;
    }

    /**
    * @dev checks that _sender is execution facility
    * @param _sender the address of the sender
    * @return true if _sender is execution facility
    **/
    function isExecutionFacility(address _sender) public view returns (bool) {
        return executionFacilities[_sender] != 0;
    }

    /**
    * @dev removes execution facility
    * @param _facility the address of the execution facility to remove
    **/
    function removeExecutionFacility(address _facility) external onlyOwner nonReentrant {
        executionFacilities[_facility] = 0;
    }

    /**
    * @dev appends execution facility
    * @param _facility the address of the execution facility to add
    **/
    function addExecutionFacility(address _facility) external onlyOwner nonReentrant {
        executionFacilities[_facility] = 1;

    }

    /**
    * @dev changes fee receiver
    * @param _feeReceiver the address of the new fee receiver
    **/
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), '_feeReceiver is address(0)');

        feeReceiver = _feeReceiver;
    }

    /**
    * @dev changes fee portion
    * @param _feePortion new fee portion with decimals 1
    **/
    function setFeePortion(uint _feePortion) external onlyOwner {
        feePortion = _feePortion;

        emit SetFeePortion(_feePortion, block.timestamp);
    }

    /**
    * @dev creates escrow
    * @param _user the address of the user
    * @param _order the order struct
    **/
    function createEscrow(
        address _user,
        Order memory _order
    ) external onlyMaster returns(uint) {
        require(_user != address(0), 'user is address(0)');

        uint escrowBalance;

        if (_order.orderType == OrderType.Sell) {
            escrowBalance = _order.baseAmount;

            if (_order.baseCurrency != AVAX_ADDRESS) {
                bool success = ERC20(_order.baseCurrency).transferFrom(_order.creator, address(this), escrowBalance);
                require(success, "error during transfer");
            }
        } else {
            if (_order.tradeType == TradeType.Limit) {
                escrowBalance = calcQuoteAmount(
                    _order.baseAmount,
                    _order.baseCurrency,
                    _order.limitPrice
                );
            } else {
                escrowBalance = _order.quoteAmount;
            }

            if (_order.quoteCurrency != AVAX_ADDRESS) {
                bool success = ERC20(_order.quoteCurrency).transferFrom(_order.creator, address(this), escrowBalance);
                require(success, "error during transfer");
            }
        }

        require(_order.gasDeposit >= basicGasDeposit, "Passed msg.value is less than basic gas deposit");
        if (_order.gasDeposit > basicGasDeposit) {
            payable(address(_user)).transfer(_order.gasDeposit - basicGasDeposit);
            _order.gasDeposit = basicGasDeposit;
        }

        escrows[escrowCount] =
        Escrow (
            _user,
            escrowBalance,
            _order
        );

        orderChanges[escrowCount].push(OrderChange (
            block.timestamp,
            OrderStatus.OpenUnfilled,
            0,
            0,
            0,
            0
        ));

        usersOpenEscrowsIds[_user].push(escrowCount);
        filteredOpenEscrowsIds[_order.orderType][_order.baseCurrency][_order.quoteCurrency].push(escrowCount);

        ++escrowCount;

        return escrowCount - 1;
    }

    /**
    * @dev cancels the order
    * @param _escrowId the escrow id
    **/
    function cancelOrder(uint _escrowId) public nonReentrant {
        require(_escrowId < escrowCount, "wrong escrow ID");

        Escrow storage escrow = escrows[_escrowId];

        require(escrow.user == msg.sender || msg.sender == master, "wrong caller");

        if (escrow.order.orderType == OrderType.Sell) {
            transferToUser(escrow.order.baseCurrency, msg.sender, escrow.balance);
        } else {
            transferToUser(escrow.order.quoteCurrency, msg.sender, escrow.balance);
        }

        escrow.balance = 0;

        closeOrder(_escrowId, 0, 0, true);

        payable(escrow.order.creator).transfer(escrow.order.gasDeposit);
        escrow.order.gasDeposit = 0;
    }

    /**
    * @dev internal function that closes the order
    * @param _escrowId the escrow id
    * @param _isCanceled true if is canceled
    **/
    function closeOrder(
        uint _escrowId,
        uint _priceFilledAt,
        uint _quantityFilled,
        bool _isCanceled
    ) internal {
        Escrow storage escrow = escrows[_escrowId];

        OrderStatus status;
        if (_isCanceled) {
            status = OrderStatus.ClosedCanceled;
        } else {
            if (escrow.order.status == OrderStatus.OpenUnfilled) {
                status = OrderStatus.ClosedFullyFilled;
            } else {
                status = OrderStatus.ClosedPartiallyFilled;
            }
        }

        escrow.order.status = status;

        updateStatusUnchecked(
            _escrowId,
            _priceFilledAt,
            _quantityFilled,
            status
        );

        uint[] storage openEscrowsIds = usersOpenEscrowsIds[escrow.user];
        uint length = openEscrowsIds.length;
        for (uint i = 0; i < length; i++) {
            if (openEscrowsIds[i] == _escrowId) {
                openEscrowsIds[i] = openEscrowsIds[length - 1];
                openEscrowsIds.pop();
                usersCloseEscrowsIds[escrow.user].push(_escrowId);
                break;
            }
        }

        uint[] storage filteredEscrowsIds = filteredOpenEscrowsIds[escrow.order.orderType][escrow.order.baseCurrency][escrow.order.quoteCurrency];
        length = filteredEscrowsIds.length;
        for (uint i = 0; i < length; i++) {
            if (filteredEscrowsIds[i] == _escrowId) {
                filteredEscrowsIds[i] = filteredEscrowsIds[length - 1];
                filteredEscrowsIds.pop();
                break;
            }
        }
    }

    /**
    * @dev internal function that exchanges assets and sends them to users
    * @param _buyEscrow the escrow of buy order
    * @param _sellEscrow the escrow of sell order
    * @param _makerOrderType the type of maker order
    **/
    function exchangeAssets(
        Escrow storage _buyEscrow,
        Escrow storage _sellEscrow,
        OrderType _makerOrderType
    ) private returns (uint) {
        address baseCurrency = _buyEscrow.order.baseCurrency;
        address quoteCurrency = _buyEscrow.order.quoteCurrency;

        require(
            _buyEscrow.balance > 0 && _sellEscrow.balance > 0,
            "Order is already closed"
        );

        uint price;
        if (_sellEscrow.order.tradeType == TradeType.Limit && _buyEscrow.order.tradeType == TradeType.Limit) {
            require(
                _sellEscrow.order.baseCurrency == baseCurrency &&
                _sellEscrow.order.quoteCurrency == quoteCurrency &&
                _sellEscrow.order.limitPrice <= _buyEscrow.order.limitPrice,
                "Currencies do not match"
            );

            price = (_makerOrderType == OrderType.Sell) ?
                _sellEscrow.order.limitPrice :
                _buyEscrow.order.limitPrice;
        } else {
            // one of the orders should be a limit order
            require(
                _sellEscrow.order.baseCurrency == baseCurrency &&
                _sellEscrow.order.quoteCurrency == quoteCurrency &&
                (_sellEscrow.order.tradeType == TradeType.Limit || _buyEscrow.order.tradeType == TradeType.Limit),
                "Currencies do not match"
            );

            // take the price of a limit order
            if (_sellEscrow.order.tradeType == TradeType.Limit) {
                price = _sellEscrow.order.limitPrice;
                _buyEscrow.order.baseAmount = calcBaseAmount(
                    _buyEscrow.balance,
                    baseCurrency,
                    price
                );
            } else {
                price = _buyEscrow.order.limitPrice;
            }
        }

        uint filled;
        uint quoteAmount;

        uint buyEscrowUserFeeAmount;
        uint sellEscrowUserFeeAmount;

        uint multiplier = (10 ** FEE_DECIMALS) * 100;
        if (_sellEscrow.balance >= _buyEscrow.order.baseAmount) {
            quoteAmount = calcQuoteAmount(
                _buyEscrow.order.baseAmount,
                baseCurrency,
                price
            );

            if (_sellEscrow.balance > (multiplier * feePortion)) {
                sellEscrowUserFeeAmount = quoteAmount * feePortion / multiplier ;
            }
            if (_buyEscrow.balance > (multiplier * feePortion)) {
                buyEscrowUserFeeAmount = _buyEscrow.order.baseAmount * feePortion / multiplier ;
            }

            if (isExecutionFacility(_buyEscrow.user)) {
                buyEscrowUserFeeAmount = 0;
            }
            transferToUser(baseCurrency, _buyEscrow.user, _buyEscrow.order.baseAmount - buyEscrowUserFeeAmount);

            if (isExecutionFacility(_sellEscrow.user)) {
                sellEscrowUserFeeAmount = 0;
            }
            transferToUser(quoteCurrency, _sellEscrow.user, quoteAmount - sellEscrowUserFeeAmount);

            filled = _buyEscrow.order.baseAmount;

            _sellEscrow.balance -= _buyEscrow.order.baseAmount;
            _sellEscrow.order.baseAmount -= _buyEscrow.order.baseAmount;
            _buyEscrow.balance -= quoteAmount;
            _buyEscrow.order.baseAmount = 0;

            if (_buyEscrow.balance > 0) {
                transferToUser(quoteCurrency, _buyEscrow.user, _buyEscrow.balance);
                _buyEscrow.balance = 0;
            }
        } else {
            quoteAmount = calcQuoteAmount(
                _sellEscrow.balance,
                baseCurrency,
                price
            );

            if (_sellEscrow.balance > (multiplier * feePortion)) {
                sellEscrowUserFeeAmount = quoteAmount * feePortion / multiplier;
            }
            if (_buyEscrow.balance > (multiplier * feePortion)) {
                buyEscrowUserFeeAmount = _sellEscrow.balance * feePortion / multiplier;
            }

            if (isExecutionFacility(_buyEscrow.user)) {
                buyEscrowUserFeeAmount = 0;
            }
            transferToUser(baseCurrency, _buyEscrow.user, _sellEscrow.balance - buyEscrowUserFeeAmount);

            if (isExecutionFacility(_sellEscrow.user)) {
                sellEscrowUserFeeAmount = 0;
            }
            transferToUser(quoteCurrency, _sellEscrow.user, quoteAmount - sellEscrowUserFeeAmount);

            filled = _sellEscrow.balance;

            _buyEscrow.balance -= quoteAmount;
            _buyEscrow.order.baseAmount -= _sellEscrow.balance;
            _sellEscrow.balance = 0;
            _sellEscrow.order.baseAmount = 0;
        }

        transferToUser(baseCurrency, feeReceiver, buyEscrowUserFeeAmount);
        transferToUser(quoteCurrency, feeReceiver, sellEscrowUserFeeAmount);

        return filled;
    }

    /**
    * @dev internal function that updates order status
    * @param _escrowId the escrow id
    * @param _priceFilledAt the price filled at (by the transaction)
    * @param _quantityFilled the quantity filled (by the transaction)
    **/
    function updateStatus(
        uint _escrowId,
        uint _priceFilledAt,
        uint _quantityFilled
    ) private {
        if (escrows[_escrowId].balance == 0) {
            closeOrder(_escrowId,  _priceFilledAt, _quantityFilled, false);
            return;
        }

        updateStatusUnchecked(
            _escrowId,
            _priceFilledAt,
            _quantityFilled,
            OrderStatus.OpenPartiallyFilled
        );
    }

    /**
    * @dev internal function that updates order status without additional checks
    * @param _escrowId the escrow id
    * @param _priceFilledAt the price filled at (by the transaction)
    * @param _quantityFilled the quantity filled (by the transaction)
    * @param _newStatus the new order status
    **/
    function updateStatusUnchecked(
        uint _escrowId,
        uint _priceFilledAt,
        uint _quantityFilled,
        OrderStatus _newStatus
    ) private {
        escrows[_escrowId].order.status = _newStatus;

        OrderChange memory lastOrderChange = orderChanges[_escrowId][orderChanges[_escrowId].length - 1];
        uint totalQuantityFilled = lastOrderChange.totalQuantityFilled + _quantityFilled;
        uint totalQuoteAmount = lastOrderChange.averagePrice * lastOrderChange.totalQuantityFilled + _quantityFilled * _priceFilledAt;

        uint averagePrice;
        if (totalQuantityFilled != 0) {
            averagePrice = totalQuoteAmount / totalQuantityFilled;
        }

        orderChanges[_escrowId].push(OrderChange (
            block.timestamp,
            _newStatus,
            _quantityFilled,
            totalQuantityFilled,
            _priceFilledAt,
            averagePrice
        ));
    }

    /**
    * @dev internal function that fills the order
    * @param _makerEscrowId the escrow id of maker order
    * @param _takerEscrowId the escrow id of taker order
    **/
    function _fill(
        uint _makerEscrowId,
        uint _takerEscrowId
    ) internal {
        require(
            _makerEscrowId < escrowCount &&
            _takerEscrowId < escrowCount &&
            _makerEscrowId != _takerEscrowId,
            "Unknown escrow"
        );

        Escrow storage makerEscrow = escrows[_makerEscrowId];
        Escrow storage takerEscrow = escrows[_takerEscrowId];

        uint quantityFilled;
        if (makerEscrow.order.orderType == OrderType.Buy) {
            quantityFilled = exchangeAssets(makerEscrow, takerEscrow, OrderType.Buy);
        } else {
            quantityFilled = exchangeAssets(takerEscrow, makerEscrow, OrderType.Sell);
        }

        updateStatus(
            _makerEscrowId,
            makerEscrow.order.limitPrice,
            quantityFilled
        );

        updateStatus(
            _takerEscrowId,
            makerEscrow.order.limitPrice,
            quantityFilled
        );
    }

    /**
    * @dev fills the order
    * @param _makerEscrowId the escrow id of maker order
    * @param _takerEscrowId the escrow id of taker order
    **/
    function fill(
        uint _makerEscrowId,
        uint _takerEscrowId
    ) external onlyExecutionFacility nonReentrant {
        uint gasAmountLeft = gasleft();

        _fill(_makerEscrowId, _takerEscrowId);

        gasCompensation(_makerEscrowId, _takerEscrowId, gasAmountLeft, msg.sender);
    }

    /**
    * @dev fills the order with extra gas compensation
    * @param _makerEscrowId the escrow id of maker order
    * @param _takerEscrowId the escrow id of taker order
    * @param _extraGas additional gas consumption before the function call
    * @param _isLastFill true if this is the last fill of the taker order
    **/
    function fillWithExtraGasCompensation(
        uint _makerEscrowId,
        uint _takerEscrowId,
        uint _extraGas,
        bool _isLastFill
    ) external onlyMaster {
        uint gasAmountLeft = gasleft() + _extraGas;

        _fill(_makerEscrowId, _takerEscrowId);

        if (_isLastFill && escrows[_takerEscrowId].order.status == OrderStatus.OpenPartiallyFilled) {
            cancelOrder(_takerEscrowId);
            if (escrows[_takerEscrowId].order.orderType == OrderType.Buy) {
                gasAmountLeft += 10414;
            } else {
                gasAmountLeft += 10412;
            }
        }

        gasCompensation(_makerEscrowId, _takerEscrowId, gasAmountLeft, escrows[_takerEscrowId].order.creator);
    }

    /**
    * @dev internal function that compensations gas
    * @param _makerEscrowId the escrow id of maker order
    * @param _takerEscrowId the escrow id of taker order
    * @param _gasAmountLeft gas amount at the start of the transaction
    * @param _user the address of the user who will receive the compensation
    **/
    function gasCompensation(
        uint _makerEscrowId,
        uint _takerEscrowId,
        uint _gasAmountLeft,
        address _user
    ) internal {
        uint compensation;

        Escrow storage makerEscrow = escrows[_makerEscrowId];
        Escrow storage takerEscrow = escrows[_takerEscrowId];

        if (makerEscrow.balance == 0) {
            compensation = (_gasAmountLeft - gasleft() + 24196) * tx.gasprice;

            if (takerEscrow.balance == 0) {
                payable(takerEscrow.order.creator).transfer(takerEscrow.order.gasDeposit);
                takerEscrow.order.gasDeposit = 0;
                compensation -= 28490 * tx.gasprice;
            }

            payable(makerEscrow.order.creator).transfer(makerEscrow.order.gasDeposit - compensation);
            makerEscrow.order.gasDeposit = 0;
        } else {
            compensation = (_gasAmountLeft - gasleft() + 24053) * tx.gasprice;
            payable(takerEscrow.order.creator).transfer(takerEscrow.order.gasDeposit - compensation);
            takerEscrow.order.gasDeposit = 0;
        }

        payable(_user).transfer(compensation);
    }

    /**
    * @dev gets the order status history
    * @param _escrowId the escrow id
    * @return the array of order status changes
    **/
    function getStatusHistory(uint _escrowId) view external returns (StatusChange[] memory) {
        StatusChange[] memory result = new StatusChange[](orderChanges[_escrowId].length);
        for (uint i = 0; i < orderChanges[_escrowId].length; i++) {
            result[i] = StatusChange(
                orderChanges[_escrowId][i].timestamp,
                orderChanges[_escrowId][i].newStatus
            );
        }
        return result;
    }

    /**
    * @dev gets the order history
    * @param _escrowId the escrow id
    * @return the array of order changes
    **/
    function getOrderHistory(uint _escrowId) view external returns (OrderChange[] memory) {
        return orderChanges[_escrowId];
    }

    /**
    * @dev gets order status
    * @param _escrowId the escrow id
    * @return the order status
    **/
    function getStatus(uint _escrowId) view external returns (OrderStatus) {
        return escrows[_escrowId].order.status;
    }

    /**
    * @dev calculates the quote amount
    * @param _baseAmount the amount of the base asset
    * @param _baseCurrency the address of the base asset
    * @param _price the amount of the quote asset needed to buy 1 unit of the base asset (_price decimals == _quoteCurrency decimals)
    * @return the quote amount
    **/
    function calcQuoteAmount(
        uint _baseAmount,
        address _baseCurrency,
        uint _price
    ) view public returns (uint) {
        return _baseAmount * _price / 10**(_baseCurrency == AVAX_ADDRESS ? 18 : ERC20(_baseCurrency).decimals());
    }

    /**
    * @dev calculates the base amount
    * @param _quoteAmount the amount of the quote asset
    * @param _baseCurrency the address of the base asset
    * @param _price the amount of the quote asset needed to buy 1 unit of the base asset (_price decimals == _quoteCurrency decimals)
    * @return the base amount
    **/
    function calcBaseAmount(
        uint _quoteAmount,
        address _baseCurrency,
        uint _price
    ) view public returns (uint) {
        return _quoteAmount * 10**(_baseCurrency == AVAX_ADDRESS ? 18 : ERC20(_baseCurrency).decimals()) / _price;
    }

    /**
    * @dev sets new value of gas deposit
    * @param _newBasicGasDeposit the new basic gas deposit value
    **/
    function setBasicGasDeposit(uint _newBasicGasDeposit) external onlyOwner nonReentrant {
        basicGasDeposit = _newBasicGasDeposit;
    }

    /**
    * @dev sets new CablesMaster contract
    * @param _cablesMaster the CablesMaster contract address
    **/
    function setMaster(address _cablesMaster) external onlyOwner nonReentrant {
        require(_cablesMaster != address(0), 'master is address(0)');
        master = _cablesMaster;

        emit SetMaster(_cablesMaster, block.timestamp);
    }

    /**
    * @dev finds a suitable match for order
    * @param _escrowId the escrow id
    * @param _fromIndex the index of the array element from which to start the search
    * @return suitableEscrowId the suitable escrow id
    *         index the index where the search stopped
    **/
    function findSuitableMatch(
        uint _escrowId,
        uint _fromIndex
    )
    public
    view
    returns (
        uint suitableEscrowId,
        uint index
    )
    {
        suitableEscrowId = type(uint).max;
        Escrow storage escrow = escrows[_escrowId];

        OrderType filteredOrderType = (escrow.order.orderType == OrderType.Sell) ? OrderType.Buy : OrderType.Sell;
        uint[] memory filteredEscrowsIds = filteredOpenEscrowsIds[filteredOrderType][escrow.order.baseCurrency][escrow.order.quoteCurrency];
        uint length = filteredEscrowsIds.length;

        Escrow storage currentEscrow;
        for (uint i = _fromIndex; i < length; i++) {
            currentEscrow = escrows[filteredEscrowsIds[i]];

            if ((escrow.order.orderType == OrderType.Buy && currentEscrow.order.limitPrice <= escrow.order.limitPrice) ||
                (escrow.order.orderType == OrderType.Sell && currentEscrow.order.limitPrice >= escrow.order.limitPrice)) {

                suitableEscrowId = filteredEscrowsIds[i];
                index = i;

                break;
            }
        }
    }

    /**
    * @dev transfers to the user a specific amount of asset from the CablesEscrow contract.
    * @param _currency the address of the asset
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _currency, address _user, uint _amount) internal {
        if (_currency == AVAX_ADDRESS) {
            payable(_user).transfer(_amount);
        } else {
            bool success = ERC20(_currency).transfer(_user, _amount);
            require(success, "error during transfer");
        }
    }

    /**
    * @dev gets the number of open orders of the user
    * @param _user the address of the user
    * @return the number of user's open orders
    **/
    function getUserOpenEscrowsCount(address _user) external view returns(uint) {
        return usersOpenEscrowsIds[_user].length;
    }

    /**
    * @dev gets the number of close orders of the user
    * @param _user the address of the user
    * @return the number of user's close orders
    **/
    function getUserCloseEscrowsCount(address _user) external view returns(uint) {
        return usersCloseEscrowsIds[_user].length;
    }

    receive() external payable {}
}


// File multisol-cablesmaster/CablesMaster.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;






/**
* @title Cables master contract
 **/
contract CablesMaster is ReentrancyGuard {
    CablesEscrow public immutable escrow;

    // the address used to identify AVAX
    address constant AVAX_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyExecutionFacility() {
        require(escrow.isExecutionFacility(msg.sender) == true, "Not Execution Facility");

        _;
    }

    constructor(CablesEscrow _escrow) {
        escrow = _escrow;
    }

    /**
    * @dev internal function to create order
    * @param _baseAmount the amount of the base asset
    * @param _quoteAmount the amount of the quote asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _limitPrice the limit base asset price (_limitPrice decimals == _quoteAsset decimals)
    * @param _orderType the order type
    * @param _tradeType the trade type
    * @param _slippage the slippage with decimals 2
    **/
    function createOrder(
        uint _baseAmount,
        uint _quoteAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _limitPrice,
        OrderType _orderType,
        TradeType _tradeType,
        uint _slippage
    ) private returns(uint) {
        uint gasDeposit;
        if (_orderType == OrderType.Sell && _baseAsset == AVAX_ADDRESS) {
            gasDeposit = msg.value - _baseAmount;
        } else if (_orderType == OrderType.Buy && _quoteAsset == AVAX_ADDRESS) {
            gasDeposit = msg.value - ((_quoteAmount == 0) ? escrow.calcQuoteAmount(_baseAmount, _baseAsset, _limitPrice) : _quoteAmount);
        } else {
            gasDeposit = msg.value;
        }

        payable(address(escrow)).transfer(msg.value);

        uint escrowId = escrow.createEscrow(
            msg.sender,
            Order ({
                baseAmount: _baseAmount,
                quoteAmount: _quoteAmount,
                creator: msg.sender,
                orderType: _orderType,
                tradeType: _tradeType,
                baseCurrency: _baseAsset,
                quoteCurrency: _quoteAsset,
                limitPrice: _limitPrice,
                executionFacility: ExecutionFacility.Nexus,
                gasDeposit: gasDeposit,
                slippage: _slippage,
                status: OrderStatus.OpenUnfilled
            })
        );

        return escrowId;
    }

    /**
    * @dev creates maker buy order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _maxPrice the max base asset price
    **/
    function createBuyOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _maxPrice
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _maxPrice, OrderType.Buy, TradeType.Limit, 0);
    }

    /**
    * @dev creates maker sell order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _minPrice the min base asset price
    **/
    function createSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _minPrice
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _minPrice, OrderType.Sell, TradeType.Limit, 0);
    }

    /**
    * @dev creates market buy order
    * @param _quoteAmount the amount of the quote asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _slippage the slippage with decimals 2
    **/
    function createMarketBuyOrder(
        uint _quoteAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _slippage
    ) external payable nonReentrant returns(uint) {
        return createOrder(0, _quoteAmount, _baseAsset, _quoteAsset, 0, OrderType.Buy, TradeType.Market, _slippage);
    }

    /**
    * @dev creates market sell order
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _slippage the slippage with decimals 2
    **/
    function createMarketSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _slippage
    ) external payable nonReentrant returns(uint) {
        return createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, 0, OrderType.Sell, TradeType.Market, _slippage);
    }

    /**
    * @dev creates taker buy order and fills it out using the maker escrows list
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _maxPrice the max base asset price
    * @param _makerEscrowsIds the array of maker escrows IDs
    **/
    function createAndFillTakerBuyOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _maxPrice,
        uint[] memory _makerEscrowsIds
    ) external payable onlyExecutionFacility nonReentrant returns(uint) {
        uint gasAmountLeft = gasleft();

        uint length = _makerEscrowsIds.length;
        require(length <= 8, "Too many maker orders to process");

        uint escrowId = createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _maxPrice, OrderType.Buy, TradeType.Limit, 0);

        uint24[8] memory gasCompensationCorrections = [116513, 143745, 170977, 198196, 225427, 252659, 279889, 351719];

        uint extraGas = (gasAmountLeft - gasleft() - gasCompensationCorrections[length-1])/length;
        for (uint i = 0; i < length; i++) {
            escrow.fillWithExtraGasCompensation(
                _makerEscrowsIds[i],
                escrowId,
                extraGas,
                i == length - 1 ? true : false
            );
        }

        return escrowId;
    }

    /**
    * @dev creates taker sell order and fills it out using the maker escrows list
    * @param _baseAmount the amount of the base asset
    * @param _baseAsset the address of the base asset
    * @param _quoteAsset the address of the quote asset
    * @param _minPrice the min base asset price
    * @param _makerEscrowsIds the array of maker escrows IDs
    **/
    function createAndFillTakerSellOrder(
        uint _baseAmount,
        address _baseAsset,
        address _quoteAsset,
        uint _minPrice,
        uint[] memory _makerEscrowsIds
    ) external payable onlyExecutionFacility nonReentrant returns(uint) {
        uint gasAmountLeft = gasleft();

        uint length = _makerEscrowsIds.length;
        require(length <= 8, "Too many maker orders to process");

        uint escrowId = createOrder(_baseAmount, 0, _baseAsset, _quoteAsset, _minPrice, OrderType.Sell, TradeType.Limit, 0);

        uint24[8] memory gasCompensationCorrections = [116534, 143766, 170997, 198215, 225447, 252682, 279910, 351744];

        uint extraGas = (gasAmountLeft - gasleft() - gasCompensationCorrections[length-1])/length;
        for (uint i = 0; i < length; i++) {
            escrow.fillWithExtraGasCompensation(
                _makerEscrowsIds[i],
                escrowId,
                extraGas,
                i == length - 1 ? true : false
            );
        }

        return escrowId;
    }
}