/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-04
*/

/*  
       ^YPB#&&&&&&&&&&&&&&&&&&&&&###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#P5G&&&&&&&&&&&&&&&&&&&&&7  
       5&&&&&&&&&###BBBBBBB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5  
       P&&&&&5?7!~~^^^^^^^^^~!7YP#&&&GYYJJ??77!J&&&&&&&P!!777??JJG&#B########&&&&#5555555555#&&&&G  
       G&&&&#^^^^^^^^^^^^^^^^^^^^^7G&B^^^^^^^^^^G&&&&&#~^^^^^^^^^B#~^^^^~~~~~B&&&#^^^^^^^^^^B&&&&#  
       G&&&&#^^^^^^^^^^^^^^^^^^^^^^^J&5^^^^^^^^^7&&&&&5^^^^^^^^^J&P^^^^^^^^^!&&&&#~^^^^^^^^^G&&&&#. 
       G&&&&#^^^^^^^^^^~!!~^^^^^^^^^^J&7^^^^^^^^^G&&&&!^^^^^^^^~#&?^^^^^^^^^Y&&&&&!^^^^^^^^^G&&&&#. 
       G&&&&#^^^^^^^^^^!&&#G~^^^^^^^^~##~^^^^^^^^7&&&P^^^^^^^^^5&&!^^^^^^^^^G&&&&#~^^^^^^^^^G&&&&#  
       B&&&&#^^^^^^^^^^!&&&&?^^^^^^^^~#&P^^^^^^^^^G&&!^^^^^^^^!&&#~^^^^^^^^~#&&&&#~^^^^^^^^^#&&&&B  
       B&&&&#^^^^^^^^^^P##G?^^^^^^^^^Y&&&?^^^^^^^^7&P^^^^^^^^^P&&#~^^^^^^^^~#&&&&B^^^^^^^^^!&&&&&Y  
       B&&&&B^^^^^^^^^^~~^^^^^^^^^^^5&&&&#~^^^^^^^^G7^^^^^^^^7&&&#~^^^^^^^^!&&&&&5^^^^^^^^^5&&&&&^  
       B&&&&B^^^^^^^^^^^^^^^^^^^^!Y#&&&&&&P^^^^^^^^~^^^^^^^^^B&&&&!^^^^^^^^~#&&&&7^^^^^^^^~#&&&&B   
       B&&&&B^^^^^^^^^^^^^~~!?YPB&&&&&&&&&&?^^^^^^^^^^^^^^^^?&&&&&Y^^^^^^^^^G&&&B^^^^^^^^^P&&&&&~   
       B&&&&B^^^^^^^^^~B###&&&&&&&&&&G#&&&&#~^^^^^^^^^^^^^^^#&&&&&B^^^^^^^^^7#&#!^^^^^^^^J&&&&&P    
       B&&&&B^^^^^^^^^~&&&&&&&&&#B5!. ~&&&&&G^^^^^^^^^^^^^^Y&&&&&&&Y^^^^^^^^^~7~^^^^^^^^?&&&&&B.    
       B&&&&B^^^^^^^^^~#&&&&B!^:.      5&&&&&J^^^^^^^^^^^^~#&&&&&&&&J^^^^^^^^^^^^^^^^^^5&&&&&#.     
       B&&&&B^^^^^^^^^~#&&&&G!?YPGGGGGPG&&&&&#~^^^^^^^^^^^5&&&&&&&&&&P!^^^^^^^^^^^^^^?B&&&&&G.      
       #&&&&B!!!!!!!!!7#&&&&&&&&&&&&&&&&&&&&&&G!!!!777???Y&&&&&&&&&&&&&GJ!~^^^^^^~?5#&&&&&&?        
       #&&&&&&&&&&&&&&&&&&&&&&&&#######&&&############&&&&#&&&&&&&&&&&&&&&##BBBB#&&&&&&&#Y.         
       #&&&&&&&&&&&&&&&&&&&#G5J??77777??G&Y????????????????B&&&&&&&&######&&&&&&&&&&&#P!.           
       ?JJJJJJJJJ?B&&&&&&BY?777777777777B&J7777777777777777B&&&&#PYJ?7777??JYG#&&&&&&P              
                 ~&&&&&#Y77777777777777?&&?7777777777777777#&&BY777777777777777YB&&&&&B.            
                :&&&&&#J77777777777??J?5&#?7777777?PGGBBBBB&&57777777777777777777P&&&&&G            
                G&&&&&J77777777?5B##&&&&&#?7777777?GGGGG#&&&Y77777777JYYJ777777777P&&&&&7           
               .&&&&&B77777777J#&&&&&&&&&#?777777777777!B&&G7777777?B&##&#J7777777?#&&&&G           
               ~&&&&&577777777G&&&&&&&&&&#77777777777777#&&57777777P&^  .BB77777777#&&&&B           
               ~&&&&&577777777Y#&&&&&&#B&#777777775BBBBB&&&P7777777J#BYJP&P7777777?&&&&&P           
               .&&&&&B777777777?Y5P55J??#B77777777PBBBBBGG&#?7777777?PBBGJ77777777G&&&&&~           
                5&&&&&P7777777777777777J&B7777777777777777#&#J7777777777777777777G&&&&&P            
                 G&&&&&GJ77777777777777Y&B777777777777777?&&&#P?777777777777777Y#&&&&&P             
                  5&&&&&&GY?7777777777?G&G!7777777777777!J&&&&&#G5J?7777777?YP#&&&&&&?              
                   ~B&&&&&&##GGPPPPGB##&&B55555555PPPPPPPG&&&&&&&&&##BBBBB##&&&&&&&Y.               
                     ^5#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#G!.                 
                        ^?5B#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&7~JPGB#####BGY7^.                                                      
                                                                                                    
                                                                                                                                                                             
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

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

    /*
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /*
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /* @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * Emits an {Approval} event.*/
    function approve(address spender, uint256 amount) external returns (bool);

    /* @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.*/

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /*
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.10;

/*
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */

interface IERC20Metadata is IERC20 {
    /*
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity 0.8.10;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.10;


/* @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.*/
abstract contract Ownable is Context {
   
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /*
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /*
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /* @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /*
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /*
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/* @dev Implementation of the {IERC20} interface.
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

    /* @dev Sets the values for {name} and {symbol}.
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

    /*
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /*
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /* @dev Returns the number of decimals used to get its user representation.
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

    /* @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`. */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*
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

    /*
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

    /*
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

    /*
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

    /* @dev Creates `amount` tokens and assigns them to `account`, increasing
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

// PVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEOPVUCEO

pragma solidity 0.8.10;
contract PVUCEO is Ownable, ERC20 {

    //Initial Definition of variables and events
    mapping(address => bool) public poolAddress;

    address public constant TAXWALLET = 0x2017a0064E6CEAA0706049cbFae74EE6b2c241E0;

    uint private constant DIVISOR = 1000;
    //Using 1000 instead of 100 as divisor to enable fractional tax changes, Please note this makes sellTax 90 = 9% & MAXTAX 150 = 15%
    uint private constant MAXTAX = 120; //establishes a maximun tax of 12%
    uint public sellTax = 90; //Initial 9% tax

    event SetPool(address poolAddress, bool status);
    event TaxUpdated(uint256 selltaxt);


    constructor() ERC20("PVU CEO", "PVUCEO") {
        _mint(msg.sender, 1000000000 ether);
    }

    function updateTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
        require(_sellTax < MAXTAX);
        emit TaxUpdated(sellTax);
    }

    function setPool(address _poolAddress, bool _status) external onlyOwner {
        poolAddress[_poolAddress] = _status;
        emit SetPool(_poolAddress, _status);
    }

    function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
        uint256 feeAmount;            
             if(poolAddress[receiver]) {          
                feeAmount = (amount * sellTax) / DIVISOR;
            }
            if(feeAmount > 0) {
                super._transfer(sender, TAXWALLET, feeAmount);
            }    
            super._transfer(sender, receiver, amount - feeAmount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(_to != address(this), "No transfers to token contract allowed.");    
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    fallback() external {
        revert();
    }

}