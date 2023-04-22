/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-21
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


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

// File: otc.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;





/// @title Over-the-counter contract for a ERC20 token. The price can be changed by the owner
contract Otc is Pausable, Ownable {
    struct Listing {
        address wallet;
        uint256 initialAmount;
        uint256 remainingAmount;
        uint256 createdAt;
        uint256 nextListingId;
        uint256 curListingId;
        uint256 prevListingId;
    }

    IERC20 public tokenAddress;
    uint8 public xetaDecimals = 18;

    IERC20 public stableCoinAddress;

    uint256 public price;

    uint256 public firstListingId = 0;
    uint256 public lastListingId = 0;
    uint256 public listingsNumber = 0;
    uint256 public listingsIndex = 1;
    uint256 public totalXetaListed = 0;

    mapping(uint256 => Listing) public listings;

    event SetTokenEvent(address indexed wallet, uint8 indexed decimals);
    event SetStableCoinEvent(address indexed wallet);
    event SetPriceEvent(uint256 indexed price);
    event ListEvent(address indexed wallet, uint256 indexed amount);
    event DelistEvent(uint256 indexed listingId);
    event BuyEvent(address indexed walletFrom, address indexed walletTo, uint256 indexed amount);
    event SellEvent(address indexed walletFrom, address indexed walletTo, uint256 indexed amount);

    constructor(address tokenAddress_, address stableCoinAddress_, uint256 initialPrice) {
        tokenAddress = IERC20(tokenAddress_);
        stableCoinAddress = IERC20(stableCoinAddress_);
        price = initialPrice;
    }

    /// @notice Lists the specified amount of ERC20 token (XETA). Approve required. Transfers this XETA to this smart contract
    /// @param amountXeta Amount of XETA to list
    /// @dev Adds this listing to the tail of the double-linked list
    function list(uint256 amountXeta) external whenNotPaused {
        require(amountXeta > 0, "amountXeta should be greater than zero");

        bool res = tokenAddress.transferFrom(msg.sender, address(this), amountXeta);
        require(res, "Error transferring XETA tokens");

        // wrong solution. Can be the same ids while 2 or more transaction will pass from the same wallet in the same block
        // uint256 id = block.timestamp + (uint256(uint160(msg.sender)) << 96); // address is 160 bits, uint256 is 256 bits. Making a 96-bit left shift
        uint256 id = listingsIndex;
        listings[id] = Listing(
            {
                wallet: msg.sender,
                initialAmount: amountXeta,
                remainingAmount: amountXeta,
                createdAt: block.timestamp,
                nextListingId: 0,
                curListingId: id,
                prevListingId: lastListingId
            }
        );
        listings[lastListingId].nextListingId = id;
        lastListingId = id;
        if (firstListingId == 0) {
            firstListingId = id;
        }

        listingsNumber++;
        listingsIndex++;
        totalXetaListed += amountXeta;

        emit ListEvent(msg.sender, amountXeta);
    }

    /// @notice Buy the specified amount of XETA for the CURRENT price. Stable token approve required
    /// @param wallet A wallet address to purchase from. If zero address is specified then it doesn't matter what wallet the purchase from
    /// @param amountXeta Amount of XETA to purchase. The purchase comes from the listing that was listed first
    function buy(address wallet, uint256 amountXeta) external whenNotPaused {
        require(stableCoinAddress.balanceOf(msg.sender) >= amountXeta * price / (10 ** xetaDecimals), "Insufficient stable coin balance");
        require(stableCoinAddress.allowance(msg.sender, address(this)) >= amountXeta * price / (10 ** xetaDecimals), "Insufficient stable coin allowance");
        require(tokenAddress.balanceOf(address(this)) >= amountXeta, "Insufficient token balance");

        uint256 amountXetaRemains = amountXeta;
        uint256 currentId = firstListingId;
        while (amountXetaRemains > 0 && currentId != 0) {
            if (wallet != address(0x0) && listings[currentId].wallet != wallet) {
                currentId = listings[currentId].nextListingId;
                continue;
            }

            uint256 xetaToTransfer = 0;
            if (listings[currentId].remainingAmount > amountXetaRemains) {
                xetaToTransfer = amountXetaRemains;
                listings[currentId].remainingAmount -= amountXetaRemains;
                emit SellEvent(msg.sender, listings[currentId].wallet, amountXetaRemains);
                amountXetaRemains = 0;
            } else {
                xetaToTransfer = listings[currentId].remainingAmount;
                amountXetaRemains -= listings[currentId].remainingAmount;
                emit SellEvent(msg.sender, listings[currentId].wallet, listings[currentId].remainingAmount);
                internalRemoveFromList(currentId);
            }

            bool res = tokenAddress.transfer(msg.sender, xetaToTransfer);
            require(res, "Insufficient XETA in the smart contract");
            res = stableCoinAddress.transferFrom(msg.sender, listings[currentId].wallet, xetaToTransfer * price / (10 ** xetaDecimals));
            require(res, "Error while transferring stable coin");

            currentId = listings[currentId].nextListingId;
        }

        require(amountXetaRemains == 0, "Insufficient XETA listings for the specified wallet address");
        totalXetaListed -= amountXeta;

        emit BuyEvent(msg.sender, wallet, amountXeta);
    }

    /// @notice Cancels the specified listing. Returns XETA tokens that was transferred by the listing
    function cancelListing(uint256 listingId) external whenNotPaused {
        require(listings[listingId].wallet == msg.sender, "You cannot cancel a listing that is not yours");

        bool res = tokenAddress.transfer(msg.sender, listings[listingId].remainingAmount);
        require(res, "Insufficient XETA in the smart contract");

        totalXetaListed -= listings[listingId].remainingAmount;

        internalRemoveFromList(listingId);
    }

    /// @notice Removes listing by the owner (in case of emergency)
    function removeFromList(uint256 listingId) external onlyOwner {
        totalXetaListed -= listings[listingId].remainingAmount;

        internalRemoveFromList(listingId);
    }

    /// @notice Set address of a token
    /// @param newAddress address of the token
    function setTokenAddress(address newAddress, uint8 newDecimals) external onlyOwner {
        require (newAddress != address(0x0), "Invalid address");
        tokenAddress = IERC20(newAddress);
        xetaDecimals = newDecimals;
        emit SetTokenEvent(newAddress, newDecimals);
    }

    /// @notice Set address of a stable coin
    /// @param newAddress address of the stable coin
    function setStableCoinAddress(address newAddress) external onlyOwner {
        require (newAddress != address(0x0), "Invalid address");
        stableCoinAddress = IERC20(newAddress);
        emit SetStableCoinEvent(newAddress);
    }

    /// @notice Set the price of token in stable coin
    /// @param newPrice the price of token in stable coin
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit SetPriceEvent(newPrice);
    }

    /// @notice Transfers the specified token from the smart contract to the specified wallet address
    /// @dev If a user sends other tokens to this smart contract, the owner can transfer it to someone (i.e. back to the user)
    function withdrawToken(address tokenContract_, address recipient_, uint256 amount_) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenContract_);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(recipient_, amount_);
    }

    /// @notice Delists all listings and transfer XETA back to users
    function delistAll() external onlyOwner {
        uint256 currentListing = firstListingId;

        while (currentListing != 0) {
            bool res = tokenAddress.transfer(listings[currentListing].wallet, listings[currentListing].remainingAmount);
            require(res, "Insufficient XETA in the smart contract");
            listings[currentListing].remainingAmount = 0;
            currentListing = listings[currentListing].nextListingId;
        }

        firstListingId = 0;
        lastListingId = 0;
        listingsNumber = 0;
        totalXetaListed = 0;
    }

    /// @notice Returns a list of active listings that was made by the current wallet address
    function getMyListings() external view returns (Listing[] memory) {
        uint256 numberOfListings = countListingsFromId(msg.sender, 0, 0);
        if (numberOfListings == 0) {
            return new Listing[](0);
        }

        Listing[] memory arrListings = new Listing[](numberOfListings);
        uint256 curArrListingsIndex = 0;
        uint256 curListingId = firstListingId;

        while (curArrListingsIndex < numberOfListings) {
            if (listings[curListingId].wallet == msg.sender) {
                arrListings[curArrListingsIndex] = listings[curListingId];
                curArrListingsIndex++;
            }
            curListingId = listings[curListingId].nextListingId;
        }

        return arrListings;
    }

    /// @notice Returns numberOfListings active listings from initialListingId
    /// @param initialListingId the initial id of a listing. If set to zero then the smart contract will get from the first one.
    /// @param numberOfListings number of listings in the order in which they appear. If set to zero then the smart contract will return all of them.
    function getListings(uint256 initialListingId, uint256 numberOfListings) public view returns (Listing[] memory) {
        uint256 curArrListingsIndex = 0;
        uint256 curListingId = initialListingId;

        if (curListingId == 0) {
            if (firstListingId == 0) {
                return new Listing[](0);
            }
            curListingId = firstListingId;
        }

        if (initialListingId == 0 && numberOfListings == 0) {
            numberOfListings = listingsNumber;
        } else {
            numberOfListings = countListingsFromId(address(0x0), curListingId, numberOfListings);
        }

        Listing[] memory arrListings = new Listing[](numberOfListings);

        while (numberOfListings > 0 && listings[curListingId].initialAmount > 0) {
            arrListings[curArrListingsIndex] = listings[curListingId];
            curListingId = listings[curListingId].nextListingId;
            numberOfListings--;
            curArrListingsIndex++;
        }

        return arrListings;
    }

    /// @notice Counts the amount of available listings for the specified wallet address. The address can be set to zero
    /// @param wallet Wallet whose listings need to be counted. The address can be set to zero - then all listings are calculated
    /// @param currentListingId The id of the first listing to count from. Can be set to zero that means the head of the list
    /// @param maxNumberOfListing The max number of listing. In case of pagination implementation. The result doesn't exceed this value. Can be set to zero that means no limit
    /// @return The amount of the actual listings from the specified currentListingId by the specified wallet address
    function countListingsFromId(address wallet, uint256 currentListingId, uint256 maxNumberOfListing) public view returns (uint256) {
        uint256 numberOfListing = 0;

        if (currentListingId == 0) {
            currentListingId = firstListingId;
        }

        if (maxNumberOfListing == 0) {
            maxNumberOfListing = listingsNumber;
        }

        while (numberOfListing < maxNumberOfListing && listings[currentListingId].remainingAmount != 0) {
            if (wallet == address(0x0)) {
                numberOfListing++;
            } else if (wallet == listings[currentListingId].wallet) {
                numberOfListing++;
            }
            currentListingId = listings[currentListingId].nextListingId;
        }

        return numberOfListing;
    }

    /// @notice Removes an id from the double-linked list of listings
    /// @param listingId The listing id to remove
    function internalRemoveFromList(uint256 listingId) internal {
        listings[listingId].remainingAmount = 0;
        if (listings[listingId].prevListingId == 0 && listings[listingId].nextListingId == 0) {
            // The single record
            listingsNumber = 0;
            firstListingId = 0;
            lastListingId = 0;
            emit DelistEvent(listingId);
            return;
        }
        if (listings[listingId].prevListingId == 0) {
            // The first record
            firstListingId = listings[listingId].nextListingId;
            listings[firstListingId].prevListingId = 0;
        } else if (listings[listingId].nextListingId == 0) {
            // The last record
            lastListingId = listings[listingId].prevListingId;
            listings[lastListingId].nextListingId = 0;
        } else {
            listings[listings[listingId].prevListingId].nextListingId = listings[listingId].nextListingId;
            listings[listings[listingId].nextListingId].prevListingId = listings[listingId].prevListingId;
        }

        listingsNumber--;

        emit DelistEvent(listingId);
    }
}