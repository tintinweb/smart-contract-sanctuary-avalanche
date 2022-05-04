/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-03
*/

// File: contracts/interfaces/IUBlood.sol



pragma solidity 0.8.11;

interface IUBlood {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/UBlood.sol



pragma solidity 0.8.11;





contract UBlood is IUBlood, ERC20, Ownable {

  constructor() ERC20("BLOOD", "BLOOD") {}

  /** PRIVATE VARS */
  // Tracks the last block that a caller has written to state
  mapping(address => uint256) private _lastWriteAddress;
  // Store admins to allow them to call certain functions
  mapping(address => bool) private _admins;
  
  /** MODIFIERS */
  modifier disallowIfSameBlock() {
    require(_lastWriteAddress[tx.origin] < block.number, "BLOOD: Nope!");
    _;
  }

  modifier onlyAdmin() {
    require(_admins[_msgSender()], "BLOOD: Only admins can call this");
    _;
  }

  /** ONLY ADMIN FUNCTIONS */
  function mint(address to, uint256 amount) external override onlyAdmin {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyAdmin {
    _burn(from, amount);
  }

  function updateOriginAccess() external override onlyAdmin {
    _lastWriteAddress[tx.origin] = block.number;
  }

  /** OVERRIDE FOR SECURITY */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20, IUBlood) disallowIfSameBlock returns (bool) {
    require(_lastWriteAddress[sender] < block.number , "BLOOD: Nope!");
    return super.transferFrom(sender, recipient, amount);
  }

  function balanceOf(address account) public view virtual override disallowIfSameBlock returns (uint256) {
    require(_lastWriteAddress[account] < block.number, "BLOOD: Nope!");
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public virtual override disallowIfSameBlock returns (bool) {
    require(_lastWriteAddress[_msgSender()] < block.number, "BLOOD: Nope!");
    return super.transfer(recipient, amount);
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    require(_lastWriteAddress[owner] < block.number , "BLOOD: Nope!");
    return super.allowance(owner, spender);
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    require(_lastWriteAddress[spender] < block.number , "BLOOD: Nope!");
    return super.approve(spender, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    require(_lastWriteAddress[spender] < block.number , "BLOOD: Nope!");
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    require(_lastWriteAddress[spender] < block.number , "BLOOD: Nope!");
    return super.decreaseAllowance(spender, subtractedValue);
  }
  
  function totalSupply() public view virtual override(ERC20, IUBlood) returns (uint256) {
    require(_lastWriteAddress[_msgSender()] < block.number, "BLOOD: Nope!");
    return super.totalSupply();
  }

  /** ONLY OWNER FUNCTIONS */
  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }
}
// File: contracts/UWLHub.sol


pragma solidity ^0.8.0;


contract UWLHub {
    
    UBlood public immutable uBlood;

    struct WhiteList{
        uint128 maxSlots;
        uint128 slotsTaken;
        uint256 id;
        uint256 price;
        string projectName;
        string description;
        bool isOpen;
        //map slot number to address
        mapping(uint256  => address) whitelist;
    }

    uint256 wlLength;

    mapping(address => bool) public blacklist;
    mapping(uint256 => WhiteList) public whitelists;

    address public owner;
    mapping(address => bool) public managers;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error WhiteListDoesNotExist();
    error BlacklistedAddress();
    error AlreadyWhiteListed();
    error WhiteListClosed();
    error WhiteListIsFull();
    error UserNotWhiteListed();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event WhiteListCreated(uint256 indexed whitelistId, uint128 maxSlots, uint256 price, string projName);
    event WLPriceUpdated(uint256 indexed whitelistId, uint256 newPrice);
    event WLMaxSlotsUpdated(uint256 indexed whitelistId, uint128 newMaxSlots);
    event WLNameUpdated(uint256 indexed whitelistId, string newProjName);
    event WLDescriptionUpdated(uint256 indexed whitelistId, string newDesc);
    event AddedToWhitelist(address indexed user, uint256 indexed whitelistId, uint128 slotsTaken);
    event DeletedFromWhitelist(address indexed user, uint256 indexed whitelistId);
    event WLOpened(uint256 indexed whitelistId);
    event WLClosed(uint256 indexed whitelistId);
    event AddedToBlacklist(address indexed user);
    event RemovedFromBlacklist(address indexed user);
    event UpdatedOwner(address indexed owner);
    event AddedManager(address indexed user);
    event RemovedManager(address indexed user);

    constructor(address _uBlood){
        uBlood = UBlood(_uBlood);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyOwnerOrManager() {
        if (msg.sender != owner || managers[msg.sender] == false) revert Unauthorized();
        _;
    }

    modifier onlyExistingWhiteList(uint id) {
        if(id >= wlLength) revert WhiteListDoesNotExist();
        _;
    }

    //function to burn blood and address be placed on whitelist
    function burnForWhiteList(uint256 id) external onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        if(!wl.isOpen) revert WhiteListClosed();
        if(blacklist[msg.sender]) revert BlacklistedAddress();
        if(wl.slotsTaken >= wl.maxSlots) revert WhiteListIsFull();
        if(isWhitelisted(id, msg.sender)) revert AlreadyWhiteListed();

        //This will fail if not enough $BLOOD is available
        uBlood.burn(msg.sender, wl.price);

        //add address to whitelist
        wl.whitelist[wl.slotsTaken++] = msg.sender;

        emit AddedToWhitelist(msg.sender, id, wl.slotsTaken);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function addManager(address user) external onlyOwner {
        managers[user] = true;
        emit AddedManager(user);
    }

    function removeManager(address user) external onlyOwner {
        managers[user] = false;
        emit RemovedManager(user);
    }

    function isOwner(address user) external view returns(bool) {
        if(user == owner) return true;
        else return false;
    }

    function isManager(address user) external view returns(bool) {
        if(user == owner) return true;
        return (managers[user]);
    }

    function createWhiteList (
        uint128 _maxSlots, 
        uint256 price, 
        string memory _projName,
        string memory desc,
        bool _isOpen
    ) external onlyOwnerOrManager returns (uint256) {
        uint256 _id = wlLength++;
        WhiteList storage wl = whitelists[_id];
        wl.id = _id;
        wl.price = price;
        wl.maxSlots = _maxSlots;
        wl.projectName = _projName;
        wl.description = desc;
        wl.isOpen = _isOpen;

        emit WhiteListCreated(_id, _maxSlots, price, _projName);

        return _id;
    }

    function setWhiteListMaxSlots(
        uint256 id, 
        uint128 newMaxSlots
    ) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.maxSlots = newMaxSlots;
        emit WLMaxSlotsUpdated(id, newMaxSlots);
    }

    function setWhiteListPrice(
        uint256 id, 
        uint256 newPrice
    ) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.price = newPrice;
        emit WLPriceUpdated(id, newPrice);
    }

    function setWhiteListName(
        uint256 id, 
        string memory newName
    ) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.projectName = newName;
        emit WLNameUpdated(id, newName);
    }

    function setWhiteListDescription(
        uint256 id, 
        string memory newDesc
    ) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.description = newDesc;
        emit WLDescriptionUpdated(id, newDesc);
    }

    function openWhiteList(uint256 id) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.isOpen = true;
        emit WLOpened(id);
    }

    function closeWhiteList(uint256 id) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        wl.isOpen = false;
        emit WLClosed(id);
    }

    //manual add address to whitelist onlyOwnerOrManager
    function manualAddToWhiteList(uint256 id, address user) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        WhiteList storage wl = whitelists[id];
        if(!wl.isOpen) revert WhiteListClosed();
        if(blacklist[user]) revert BlacklistedAddress();
        if(wl.slotsTaken >= wl.maxSlots) revert WhiteListIsFull();
        if(isWhitelisted(id, user)) revert AlreadyWhiteListed();

        wl.whitelist[wl.slotsTaken++] = user;
        
        emit AddedToWhitelist(user, id, wl.slotsTaken);
    }

    //manual delete address to whitelist onlyOwnerOrManager
    function manualDeleteFromWhiteList(uint256 id, address user) external onlyOwnerOrManager onlyExistingWhiteList(id) {
        bool found;
        WhiteList storage wl = whitelists[id];
        for(uint256 i=0; i < wl.slotsTaken; i++){
            if(wl.whitelist[i] == user) {
                delete wl.whitelist[i];
                wl.slotsTaken--;
                found = true;
                emit DeletedFromWhitelist(user, id);
            }
            if(found){
                wl.whitelist[i] = wl.whitelist[i+1];
            }
        }     
        if (!found) revert UserNotWhiteListed();
    }

    function getWhiteList(uint256 whitelistId) external view returns (address[] memory, uint128, uint128){
        address[] memory wl = new address[](whitelists[whitelistId].slotsTaken);
        for (uint i = 0; i < whitelists[whitelistId].slotsTaken; i++) {
            wl[i] = whitelists[whitelistId].whitelist[i];
        }
        return (wl,whitelists[whitelistId].slotsTaken,whitelists[whitelistId].maxSlots);
    }

    //check if address is on whitelist
    function isWhitelisted(uint256 whitelistId, address user) public view returns(bool){
        WhiteList storage wl = whitelists[whitelistId];
        for(uint256 i=0; i < wl.slotsTaken; i++){
            if(wl.whitelist[i] == user) return true;
        }
        return false;
    }

    //need to keep a blacklist
    function addToBlackList(address user) external onlyOwnerOrManager {
        blacklist[user] = true;
        
        emit AddedToBlacklist(user);
    }

    function removeFromBlackList(address user) external onlyOwnerOrManager {
        blacklist[user] = false;
        
        emit RemovedFromBlacklist(user);
    }

    function isBlacklisted(address user) public view returns(bool) {
        return (blacklist[user]);
    }
}