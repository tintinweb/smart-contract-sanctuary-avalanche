/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-14
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: Farmvax_20_03_2023_19h_36/Space fox/ercToken.sol


pragma solidity ^0.8.0;



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract Ore is ERC20, Ownable{

    mapping(address => bool) admins;
    uint public constant MAX_SUPPLY = 420690000000000000000000000000000;
    address public constant TAX_ADDRESS = 0x4BC5D5DF9F3F8caC1121B3b43B52a6c66a3761Ed;
    uint public constant TAX_RATE = 3; // 3%
    address public constant AVAX_TOKEN = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // Avalanche AVAX Token Address 
    address public constant PANGOLIN_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;

    event TaxPaid(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 value);

    constructor() ERC20("Ore", "OREV1") {}

    function mint(address _to, uint _amount) external {
        require(admins[msg.sender], "Cannot mint if not admin");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Cannot mint more than max supply");
        _mint(_to, _amount);
    }
    
    function burn(uint256 _value) external onlyOwner{
        require(admins[msg.sender], "Cannot burn if not admin");
        address sender = msg.sender;


        emit Burn(sender, _value);
        emit Transfer(sender, address(0), _value);
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
    }

    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        uint256 taxAmount = calculateTax(_amount);
        uint256 tokensAfterTax = _amount - taxAmount;
        super.transfer(_recipient, tokensAfterTax);

        if (taxAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = AVAX_TOKEN;

            uint256 amountIn = taxAmount;
            IERC20(address(this)).approve(PANGOLIN_ROUTER, amountIn);

            IUniswapV2Router02(PANGOLIN_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp + 10
            );

            emit TaxPaid(msg.sender, TAX_ADDRESS, taxAmount);
        }

        return true;
    }   

    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
        uint256 taxAmount = calculateTax(_amount);
        uint256 tokensAfterTax = _amount - taxAmount;
        super.transferFrom(_sender, _recipient, tokensAfterTax);

        if (taxAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = AVAX_TOKEN;

            uint256 amountIn = taxAmount;
            IERC20(address(this)).approve(PANGOLIN_ROUTER, amountIn);

            IUniswapV2Router02(PANGOLIN_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp + 10
            );

            emit TaxPaid(_sender, TAX_ADDRESS, taxAmount);
        }

        return true;
    }

    function calculateTax(uint256 _amount) internal pure returns (uint256) {
        return _amount * TAX_RATE / 100;
    }
}

// File: Farmvax_20_03_2023_19h_36/Space fox/MyNft.sol


pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
contract IROBOTS is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 200;
  uint256 public maxMintAmount = 5;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  constructor() ERC721("irobots", "robots") {
    setBaseURI("https://gateway.pinata.cloud/ipfs/QmfE4CpF46xJqNvsQXKFyghhkpXUvtAGndSsiSSsgiPgDS/");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount, "not the good price");
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}
// File: Farmvax_20_03_2023_19h_36/Space fox/nftstaking.sol


pragma solidity ^0.8.0;




contract NFTstaking{

    uint totalStaked;
    uint constant MINUTES = 60;
    uint constant SECONDS_PER_MINUTE = 60;
    uint constant THIRTY_MINUTES = MINUTES * SECONDS_PER_MINUTE;
    uint baseRewards = 28 * (10 ** 18);
    uint baseRewardsB = 34 * (10 ** 18);
    uint baseRewardsC = 41 * (10 ** 18);
    uint baseRewardsIron = 1 * (10 ** 18);
    address contractOwner = 0xC98EEf39CCF5129A8b4917Fa043b0034d6118197;
    
    struct Staking{
        uint24 tokenId;
        uint48 stakingStartTime;
        address owner;
    }

    struct levelUpInfo {
        uint level;
        uint levelUpCost;
        uint lastLvlUpTimer;
        bool aproved;
    }
    mapping(uint => Staking) NFTsStakedA;
    mapping(uint => Staking) NFTsStakedB;
    mapping(uint => Staking) NFTsStakedC;
    mapping(uint => Staking) NFTsStakedIronMine;
    mapping (uint => levelUpInfo) public stakingRatesByNFT;

    Ore oreToken;
    IROBOTS spaceFox;

    event StakedA(address indexed owner, uint tokenId, uint value);
    event UnstakedA(address indexed owner, uint tokenId, uint value);
    event ClaimedA(address indexed owner, uint amount);

    event StakedB(address indexed owner, uint tokenId, uint value);
    event UnstakedB(address indexed owner, uint tokenId, uint value);
    event ClaimedB(address indexed owner, uint amount);

    event StakedC(address indexed owner, uint tokenId, uint value);
    event UnstakedC(address indexed owner, uint tokenId, uint value);
    event ClaimedC(address indexed owner, uint amount);

    event StakedIronMine(address indexed owner, uint tokenId, uint value);
    event UnstakedIronMine(address indexed owner, uint tokenId, uint value);
    event ClaimedIronMine(address indexed owner, uint amount);

    constructor(Ore _token, IROBOTS _nft){
        oreToken = _token;
        spaceFox = _nft;
    }
    function _random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.timestamp
        ))) % 100;
    }
    function isTrue15() public view returns(bool){
        uint number15 = _random();
        if( number15 > 84){
            return (false);
        }else{
            return (true);
        } 
    }
    function isTrue25() public view returns(bool){
        uint number25 = _random();
        if( number25 > 74){
            return (false);
        }else{
            return (true);
        } 
    }
    // MINE A
    // function to stake your spaceFox
    function StakeMineA(uint[] calldata tokenIds) external {
        uint tokenId;
        totalStaked += tokenIds.length;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(spaceFox.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTsStakedA[tokenId].stakingStartTime == 0, "Already staked");


            spaceFox.transferFrom(msg.sender, address(this), tokenId);
            emit StakedA(msg.sender, tokenId, block.timestamp);

            NFTsStakedA[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }        
    }
    // set base rewards
    function setRewardsA(uint _rewardsAmount) external{
        require(msg.sender == contractOwner);
        baseRewards = _rewardsAmount;
    }
    // function to unstake your spaceFox
    function _unstakeManyA(address owner, uint[] calldata tokenIds) internal{
        uint tokenId;
        totalStaked -= tokenIds.length;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(NFTsStakedA[tokenId].owner == msg.sender, "Not the owner");

            emit UnstakedA(owner, tokenId, block.timestamp);
            delete NFTsStakedA[tokenId];

            spaceFox.transferFrom(address(this), owner, tokenId);
        }
    }
    // function to claim w/o unstaking
    function claimA(uint[] calldata tokenIds) external {
        _claimA(msg.sender, tokenIds, false);
    }
    // function to claim w unstaking
    function unstakeA(uint[] calldata tokenIds) external {
        _claimA(msg.sender, tokenIds, true);
    }
    // function to claim rewards w or w/o unstaking
    function _claimA(address owner, uint[] calldata tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedA[tokenId];
            require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewards;
            totalEarned += earned;

            NFTsStakedA[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }

        if(totalEarned > 0){
            oreToken.mint(owner, totalEarned);
        }
        if(_unstake){
            _unstakeManyA(owner, tokenIds);
        }
        emit ClaimedA(owner, totalEarned);

    }
    // show your rewards 
    function getRewardAmountA(uint[] calldata tokenIds) external view returns(uint){
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedA[tokenId];
            //require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewards;
            totalEarned += earned;
        }
        return totalEarned;
    }
    // show staked nfts
    function tokenStakedAByOwner(address owner) external view returns(uint[] memory){
        uint totalSupply = spaceFox.totalSupply();
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0; i < totalSupply; i++){
            if(NFTsStakedA[i].owner == owner){
                tmp[index] = i;
                index++;
            }
        }
        uint[] memory tokens = new uint[](index);
        for(uint i =0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }
    // MINE B
// function to stake your spaceFox mine B
    function StakeMineB(uint[] calldata tokenIds) external {
        uint tokenId;
        totalStaked += tokenIds.length;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(spaceFox.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTsStakedB[tokenId].stakingStartTime == 0, "Already staked");


            spaceFox.transferFrom(msg.sender, address(this), tokenId);
            emit StakedB(msg.sender, tokenId, block.timestamp);

            NFTsStakedB[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }        
    }
    // set base rewards mine B
    function setRewardsB(uint _rewardsAmount) external{
        require(msg.sender == contractOwner);
        baseRewardsB = _rewardsAmount;
    }
    // function to unstake your spaceFox mine B
    function _unstakeManyB(address owner, uint[] calldata tokenIds) internal{
        uint tokenId;
        totalStaked -= tokenIds.length;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(NFTsStakedB[tokenId].owner == msg.sender, "Not the owner");

            emit UnstakedB(owner, tokenId, block.timestamp);
            delete NFTsStakedB[tokenId];

            spaceFox.transferFrom(address(this), owner, tokenId);
        }
    }
    // function to claim w/o unstaking mine B
    function claimB(uint[] calldata tokenIds) external {
        _claimB(msg.sender, tokenIds, false);
    }
    // function to claim w unstaking mine B
    function unstakeB(uint[] calldata tokenIds) external {
        _claimB(msg.sender, tokenIds, true);
    }
    // function to claim rewards w or w/o unstaking mine B
    function _claimB(address owner, uint[] calldata tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedB[tokenId];
            require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewardsB;
            bool didYouLostIt = isTrue15();
            if(didYouLostIt == false){
                earned = 0;
            }
            totalEarned += earned;

            NFTsStakedB[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }

        if(totalEarned > 0){
            oreToken.mint(owner, totalEarned);
        }
        if(_unstake){
            _unstakeManyB(owner, tokenIds);
        }
        emit ClaimedB(owner, totalEarned);

    }
    // show your rewards mine B
    function getRewardAmountB(uint[] calldata tokenIds) external view returns(uint){
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedB[tokenId];
            //require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewardsB;
            totalEarned += earned;
        }
        return totalEarned;
    }
    // show staked nfts mine B
    function tokenStakedByOwner(address owner) external view returns(uint[] memory){
        uint totalSupply = spaceFox.totalSupply();
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0; i < totalSupply; i++){
            if(NFTsStakedB[i].owner == owner){
                tmp[index] = i;
                index++;
            }
        }
        uint[] memory tokens = new uint[](index);
        for(uint i =0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }
    // MINE C
    // function to stake your spaceFox mine C
    function StakeMineC(uint[] calldata tokenIds) external {
        uint tokenId;
        totalStaked += tokenIds.length;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(spaceFox.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTsStakedC[tokenId].stakingStartTime == 0, "Already staked");


            spaceFox.transferFrom(msg.sender, address(this), tokenId);
            emit StakedC(msg.sender, tokenId, block.timestamp);

            NFTsStakedC[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }        
    }
    // set base rewards mine C
    function setRewardsC(uint _rewardsAmount) external{
        require(msg.sender == contractOwner);
        baseRewardsC = _rewardsAmount;
    }
    // function to unstake your spaceFox mine C
    function _unstakeManyC(address owner, uint[] calldata tokenIds) internal{
        uint tokenId;
        totalStaked -= tokenIds.length;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(NFTsStakedC[tokenId].owner == msg.sender, "Not the owner");

            emit UnstakedC(owner, tokenId, block.timestamp);
            delete NFTsStakedC[tokenId];

            spaceFox.transferFrom(address(this), owner, tokenId);
        }
    }
    // function to claim w/o unstaking mine C
    function claimC(uint[] calldata tokenIds) external {
        _claimC(msg.sender, tokenIds, false);
    }
    // function to claim w unstaking mine C
    function unstakeC(uint[] calldata tokenIds) external {
        _claimC(msg.sender, tokenIds, true);
    }
    // function to claim rewards w or w/o unstaking mine C
    function _claimC(address owner, uint[] calldata tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedC[tokenId];
            require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewardsC;
            bool didYouLostIt = isTrue25();
            if(didYouLostIt == false){
                earned = 0;
            }
            totalEarned += earned;

            NFTsStakedC[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }

        if(totalEarned > 0){
            oreToken.mint(owner, totalEarned);
        }
        if(_unstake){
            _unstakeManyC(owner, tokenIds);
        }
        emit ClaimedC(owner, totalEarned);

    }
    // show your rewards mine C
    function getRewardAmountC(uint[] calldata tokenIds) external view returns(uint){
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedC[tokenId];
            //require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewardsC;
            totalEarned += earned;
        }
        return totalEarned;
    }
    // show staked nfts mine C
    function tokenStakedCByOwner(address owner) external view returns(uint[] memory){
        uint totalSupply = spaceFox.totalSupply();
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0; i < totalSupply; i++){
            if(NFTsStakedC[i].owner == owner){
                tmp[index] = i;
                index++;
            }
        }
        uint[] memory tokens = new uint[](index);
        for(uint i =0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }
    function depositToken(uint _amount) public payable {
        // Transfer the tokens.
        oreToken.transferFrom(msg.sender, address(this), _amount);
    }



// IRON MINE
    // function to stake your spaceFox iron mine
    function StakeIronMine(uint[] calldata tokenIds) external {
        uint tokenId;
        totalStaked += tokenIds.length;
        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(stakingRatesByNFT[tokenId].level == 40);
            require(spaceFox.ownerOf(tokenId) == msg.sender, "Not the owner");
            require(NFTsStakedIronMine[tokenId].stakingStartTime == 0, "Already staked");


            spaceFox.transferFrom(msg.sender, address(this), tokenId);
            emit StakedIronMine(msg.sender, tokenId, block.timestamp);

            NFTsStakedIronMine[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }        
    }
    // set base rewards
    function setRewardsIron(uint _rewardsAmount) external{
        require(msg.sender == contractOwner);
        baseRewardsIron = _rewardsAmount;
    }
    // function to unstake your spaceFox
    function _unstakeManyIronMine(address owner, uint[] calldata tokenIds) internal{
        uint tokenId;
        totalStaked -= tokenIds.length;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            require(NFTsStakedIronMine[tokenId].owner == msg.sender, "Not the owner");

            emit UnstakedIronMine(owner, tokenId, block.timestamp);
            delete NFTsStakedIronMine[tokenId];

            spaceFox.transferFrom(address(this), owner, tokenId);
        }
    }
    // function to claim w/o unstaking
    function claimIronMine(uint[] calldata tokenIds) external {
        _claimIronMine(msg.sender, tokenIds, false);
    }
    // function to claim w unstaking
    function unstakeIronMine(uint[] calldata tokenIds) external {
        _claimIronMine(msg.sender, tokenIds, true);
    }
    // function to claim rewards w or w/o unstaking
    function _claimIronMine(address owner, uint[] calldata tokenIds, bool _unstake) internal {
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedIronMine[tokenId];
            require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewards;
            totalEarned += earned;

            NFTsStakedIronMine[tokenId] = Staking({
                tokenId: uint24(tokenId),
                stakingStartTime: uint48(block.timestamp),
                owner: msg.sender
            });
        }

        if(totalEarned > 0){
            oreToken.mint(owner, totalEarned);
        }
        if(_unstake){
            _unstakeManyA(owner, tokenIds);
        }
        emit ClaimedIronMine(owner, totalEarned);

    }
    // show your rewards 
    function getRewardAmountIronMine(uint[] calldata tokenIds) external view returns(uint){
        uint tokenId;
        uint earned;
        uint totalEarned;

        for(uint i = 0; i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Staking memory thisStake = NFTsStakedIronMine[tokenId];
            //require(thisStake.owner == msg.sender, "Not the owner, you can't claim the rewards");

            uint stakingStartTime = thisStake.stakingStartTime;

            earned = (uint256(block.timestamp) - stakingStartTime) * baseRewards;
            totalEarned += earned;
        }
        return totalEarned;
    }
    // show staked nfts
    function tokenStakedIronMineByOwner(address owner) external view returns(uint[] memory){
        uint totalSupply = spaceFox.totalSupply();
        uint[] memory tmp = new uint[](totalSupply);
        uint index = 0;

        for(uint i = 0; i < totalSupply; i++){
            if(NFTsStakedIronMine[i].owner == owner){
                tmp[index] = i;
                index++;
            }
        }
        uint[] memory tokens = new uint[](index);
        for(uint i =0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }

    // aprove spaceFox
    function aproveUpgrading(uint _nftId)public{
        require(stakingRatesByNFT[_nftId].aproved == false, "already aproved");
        stakingRatesByNFT[_nftId] = levelUpInfo({
            level : 1,
            levelUpCost: 59000,
            lastLvlUpTimer : 1,
            aproved : true
        });
    }
    // upgrade spaceFox 
    function upgradeStakingRate(uint256 _nftId) public payable {
        require(stakingRatesByNFT[_nftId].aproved == true, "not approved");
        require(stakingRatesByNFT[_nftId].level < 40, "you're at the max level on this NFT");
        require(msg.sender == address(oreToken), "token not accepted");
        require(block.timestamp > stakingRatesByNFT[_nftId].lastLvlUpTimer + block.timestamp, "You have to wait before next lvl up");

        oreToken.transferFrom(msg.sender, address(this), stakingRatesByNFT[_nftId].levelUpCost);
        levelUpInfo storage _levelUpInfo = stakingRatesByNFT[_nftId];
        _levelUpInfo.level++;
        _levelUpInfo.levelUpCost = _levelUpInfo.levelUpCost * 105/100;
        _levelUpInfo.lastLvlUpTimer = 17280;
        stakingRatesByNFT[_nftId] = _levelUpInfo;


    }
    function getLevel(uint _nftId) public view returns(uint, uint, uint, bool) {
        //require(NFTsStaked[_nftId].owner == msg.sender);
        levelUpInfo memory thisStake = stakingRatesByNFT[_nftId];
        return (
            thisStake.level, 
            thisStake.levelUpCost,
            thisStake.lastLvlUpTimer,
            thisStake.aproved
        );
    }

    function trytoburn(uint _amount) public{
        oreToken.burn(_amount);
    }
}