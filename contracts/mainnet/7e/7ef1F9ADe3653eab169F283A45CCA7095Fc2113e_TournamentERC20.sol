/**
 *Submitted for verification at snowtrace.io on 2022-06-12
*/

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: contracts/IWhitelist.sol



pragma solidity 0.8.9;

interface IWhitelist {
    // total size of the whitelist
    function wlSize() external view returns (uint256);
    // max number of wl spot sales
    function maxSpots() external view returns (uint256);
    // price of the WL spot
    function spotPrice() external view returns (uint256);
    // number of wl spots sold
    function spotCount() external view returns (uint256);
    // glad/wl sale has started
    function started() external view returns (bool);
    // wl sale has ended
    function wlEnded() external view returns (bool);
    // glad sale has ended
    function gladEnded() external view returns (bool);
    // total glad sold (wl included)
    function totalPGlad() external view returns (uint256);
    // total whitelisted glad sold
    function totalPGladWl() external view returns (uint256);

    // minimum glad amount buyable
    function minGladBuy() external view returns (uint256);
    // max glad that a whitelisted can buy @ discounted price
    function maxWlAmount() external view returns (uint256);

    // pglad sale price (for 100 units, so 30 means 0.3 avax / pglad)
    function pGladPrice() external view returns (uint256);
    // pglad wl sale price (for 100 units, so 20 means 0.2 avax / pglad)
    function pGladWlPrice() external view returns (uint256);

    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256);
    // get the amount of wl plgad purchased
    function pGladWl(address _a) external view returns (uint256);

    // buy whitelist spot, avax value must be sent with transaction
    function buyWhitelistSpot() external payable;

    // buy pglad, avax value must be sent with transaction
    function buyPGlad(uint256 _amount) external payable;

    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool);
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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

// File: contracts/Controllable.sol



pragma solidity 0.8.9;


contract Controllable is Ownable {
    mapping (address => bool) controllers;

    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }


}

// File: contracts/Whitelist.sol



pragma solidity 0.8.9;




contract Whitelist is IWhitelist, Controllable {
    mapping (address => bool) public whitelisted;
    uint256 public wlSize;
    uint256 public maxSpots = 150;
    uint256 public spotCount;
    uint256 public spotPrice = 3 ether;
    bool public started;
    bool public wlEnded;
    bool public gladEnded;
    uint256 public totalPGlad;
    uint256 public totalPGladWl;
    bool public wlLocked;

    uint256 public minGladBuy = 1 ether;
    uint256 public maxWlAmount = 1000 ether;
    // per 100 wei
    uint256 public pGladPrice = 30;
    // per 100 wei
    uint256 public pGladWlPrice = 20;


    mapping (address => uint256) public pGlad;
    mapping (address => uint256) public pGladWl;


    event PGladBuyWl(address user, uint256 amount);
    event PGladBuy(address user, uint256 amount);
    event Whitelisted(address user);
    event RemovedFromWhitelist(address user);

    constructor () {
    }

    function buyWhitelistSpot() external payable {
        require(started, "Sale not started yet");
        require(!wlEnded, "Whitelist sale already ended");
        require(!whitelisted[_msgSender()], "Already whitelisted");
        require(spotCount < maxSpots, "Wl spots sold out");
        require(msg.value == spotPrice, "Please send exact price");
        whitelisted[_msgSender()] = true;
        spotCount++;
        wlSize++;
        Address.sendValue(payable(owner()), msg.value);
        emit Whitelisted(_msgSender());
    }

    function buyPGlad(uint256 _amount) external payable {
        require(started, "Sale not started yet");
        require(!gladEnded, "pGlad sale already ended");
        require(_amount >= 1 ether, "Buy at least 1");
        uint256 sumPrice;
        uint256 wlAmount;
        if (whitelisted[_msgSender()] && pGladWl[_msgSender()] < maxWlAmount) {
            wlAmount = maxWlAmount - pGladWl[_msgSender()];
            if (wlAmount > _amount) {
                wlAmount = _amount;
            }
            pGladWl[_msgSender()] += wlAmount;
            totalPGladWl += wlAmount;
            emit PGladBuyWl(_msgSender(), wlAmount);
            sumPrice = wlAmount * pGladWlPrice / 100;
        }
        sumPrice += (_amount - wlAmount) * pGladPrice / 100;
        pGlad[_msgSender()] += _amount;
        require(msg.value == sumPrice, "Send exact amount pls");
        emit PGladBuy(_msgSender(), _amount);
        totalPGlad += _amount;
        Address.sendValue(payable(owner()), msg.value);
    }

    /*** GETTERS ***/
    function isWhitelisted(address _a) external view returns (bool) {
        return whitelisted[_a];
    }

    /*** MANAGE ***/

    function batchAddToWhitelist(address[] calldata _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        for (uint256 i = 0; i < _a.length; i++) {
            _addToWhitelist(_a[i]);
        }
    }

    function addToWhitelist(address _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        _addToWhitelist(_a);
    }

    function _addToWhitelist(address _a) internal {
        if (!whitelisted[_a]) {
            whitelisted[_a] = true;
            wlSize++;
            emit Whitelisted(_a);
        }
    }

    function batchRemoveFromWhitelist(address[] calldata _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        for (uint256 i = 0; i < _a.length; i++) {
            _removeFromWhitelist(_a[i]);
        }
    }

    function removeFromWhitelist(address _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        _removeFromWhitelist(_a);
    }

    function _removeFromWhitelist(address _a) internal {
        if (whitelisted[_a]) {
            require(!started, "Wl purchase already started");
            whitelisted[_a] = false;
            wlSize--;
            emit RemovedFromWhitelist(_a);
        }
    }

    function lockWhitelist() external onlyOwner {
        require(!wlLocked, "Already locked");
        wlLocked = true;
    }

    function setMaxSpots(uint256 _x) external onlyOwner {
        require(_x >= spotCount, "There are already more spots sold");
        maxSpots = _x;
    }

    function setSpotPrice(uint256 _p) external onlyOwner {
        require(_p > 0, "make it > 0");
        spotPrice = _p;
    }

    function startSale() external onlyOwner {
        require(!started, "Sale already started");
        started = true;
    }

    function endWlSale() external onlyOwner {
        require(started, "Wl purchase did not start yet");
        wlEnded = true;
    }

    function endGladSale() external onlyOwner {
        require(started, "Glad purchase did not start yet");
        gladEnded = true;
    }

}

// File: contracts/ITournament.sol



pragma solidity 0.8.9;

interface ITournament {
    function winner() external view  returns (address); // returns address of the last bidder
    function claimed() external view returns (bool); // returns true if the winner has already claimed the prize
    function pgClaimed(address user) external view returns (bool); // returns true if the given user has already claimed his/her share in the prize as a pglad owner
    function lastTs() external view returns (uint256); // last buy time
    function CLAIM_PERIOD() external view returns (uint256); // reward can be claimed for this many time until expiration(latTs)
    function PERIOD() external view returns (uint256); // time to win
    function ROUND() external view returns (uint256); // time until first earning
    function BREAKEVEN() external view returns (uint256); // breakeven time after ROUND
    function TICKET_SIZE() external view returns (uint256); // 10000th of pot
    function POT_SHARE() external view returns (uint256); // 10000th of ticketprice
    function GLAD_SHARE() external view returns (uint256); // 10000th of ticketprice
    
    event TicketBought(uint256 timestamp, uint256 ticketPrice, address oldWinner, address newWinner, uint256 reward);
    event WinnerClaimed(uint256 timestamp, address winner, uint256 reward);
    event PgladBuyerClaimed(uint256 timestamp, address winner, uint256 reward);


    function getPotSize() external view returns (uint256); // returns actual pot size
    function getGladPotSize() external view returns (uint256); // returns total accumulated pglad pot size
    function getTicketPrice() external view returns (uint256); // return current ticket price

    function buy() external payable; // buy a ticket (token should be approved, if native then exact amount must be sent)

    function claimWinner() external; // winner can claim pot
    function claimPglad() external; // pglad buyers can claim their share (after whitelist pgladsale ended)
    function withdrawUnclaimed() external; // treasury can claim remaining afte CLAIM_PERIOD
}

// File: contracts/TournamentERC20.sol



pragma solidity 0.8.9;





contract TournamentERC20 is Ownable, ITournament {
    address public winner;
    bool public claimed;
    mapping(address => bool) public pgClaimed;
    uint256 public lastTs;
    uint256 public CLAIM_PERIOD = 60 days;
    uint256 public PERIOD = 3 hours;
    uint256 public ROUND = 15 minutes;
    uint256 public BREAKEVEN = 2 hours;
    uint256 public TICKET_SIZE; // 10000th of pot
    uint256 public POT_SHARE; // 10000th
    uint256 public GLAD_SHARE; // 10000th
    uint256 public BURN_SHARE; // 10000th
    ERC20Burnable public rewardToken;
    Whitelist public wl;

    uint256 finalPotSize;
    uint256 gladPotSize;
    uint256 gladPotClaimed;

    constructor (address _wl, address _token, uint256 _periodSeconds, uint256 _roundSeconds, uint256 _breakevenSeconds, uint256 _ticketSize, uint256 _potShare, uint256 _gladShare, uint256 _burnShare, address _treasury) {
        rewardToken = ERC20Burnable(_token);
        wl = Whitelist(_wl);
        TICKET_SIZE = _ticketSize;
        POT_SHARE = _potShare;
        GLAD_SHARE = _gladShare;
        BURN_SHARE = _burnShare;
        PERIOD = _periodSeconds;
        ROUND = _roundSeconds;
        BREAKEVEN = _breakevenSeconds;
        require(GLAD_SHARE + POT_SHARE + BURN_SHARE <= 10000);
        _transferOwnership(_treasury);
    }

    function getPotSize() public view returns (uint256) {
        return _getPotSize();
    }

    function _getPotSize() internal view returns (uint256) {
        if (finalPotSize > 0) {
            return finalPotSize;
        }
        return rewardToken.balanceOf(address(this)) + gladPotClaimed - gladPotSize;
    }

    function getGladPotSize() public view returns (uint256) {
        return gladPotSize;
    }

    function getTicketPrice() public view returns (uint256) {
        return _getTicketPrice();
    }

    function _getTicketPrice() internal view returns (uint256) {
        return (_getPotSize() * TICKET_SIZE) / 10000;
    }

    function buy() external payable {
        require(msg.value == 0, "This is for ERC20 tokens, don't send AVAX");
        require(lastTs == 0 || block.timestamp < lastTs + PERIOD, "Expired");
        require(_getPotSize() > 0, "Pot not initialized yet");
        uint256 reward;
        uint256 delta_t;
        uint256 ticketPrice = _getTicketPrice();

        if (lastTs != 0) {
            delta_t = (block.timestamp - lastTs);
        }

        lastTs = block.timestamp;

        if (delta_t > ROUND) {
            reward = (ticketPrice * (delta_t - ROUND)) / BREAKEVEN;
            // best effort delivery, no require to avoid any possible revert tricks
            address(rewardToken).call(abi.encodeWithSignature("transfer(address,uint256)", winner, reward));
            //rewardToken.transfer(winner, reward);
        }

        emit TicketBought(block.timestamp, ticketPrice, winner, msg.sender, reward);
        uint256 oldBalance = rewardToken.balanceOf(address(this));
        rewardToken.transferFrom(msg.sender, address(this), ticketPrice);
        uint256 transferSize = rewardToken.balanceOf(address(this)) - oldBalance;
        require(transferSize > 0, "Transfer of ticket price failed");
        gladPotSize += transferSize * GLAD_SHARE / 10000;
        if (BURN_SHARE >  0) {
            rewardToken.burn(transferSize * BURN_SHARE / 10000);
        }
        
        if (10000 - POT_SHARE - GLAD_SHARE - BURN_SHARE > 0) {
            rewardToken.transfer(owner(), transferSize * (10000 - POT_SHARE - GLAD_SHARE - BURN_SHARE) / 10000);
        }
        winner = msg.sender;
    }

    function claimWinner() external {
        require(lastTs != 0, "Not started yet");
        require(block.timestamp >= lastTs + PERIOD, "Not finished yet");
        require(block.timestamp <= lastTs + CLAIM_PERIOD, "Claim period ended");
        require(msg.sender == winner, "You are not the winner");
        require(!claimed, "Already claimed");
        claimed = true;
        finalPotSize = _getPotSize();
        emit WinnerClaimed(block.timestamp, msg.sender, finalPotSize);
        rewardToken.transfer(msg.sender, finalPotSize);
    }

    function claimPglad() external {
        require(lastTs != 0, "Not started yet");
        require(block.timestamp >= lastTs + PERIOD, "Not finished yet");
        require(block.timestamp <= lastTs + CLAIM_PERIOD, "Claim period ended");
        require(wl.gladEnded(), "pGlad sale not ended yet");
        require(wl.pGlad(msg.sender) > 0, "You don't own any pGlad");
        require(!pgClaimed[msg.sender], "Already claimed");
        pgClaimed[msg.sender] = true;
        uint256 reward = gladPotSize * wl.pGlad(msg.sender) / wl.totalPGlad();
        gladPotClaimed += reward;
        emit PgladBuyerClaimed(block.timestamp, msg.sender, reward);
        rewardToken.transfer(msg.sender, reward);
    }

    function withdrawUnclaimed() external {
        require(lastTs != 0, "Not started yet");
        require(block.timestamp >= lastTs + CLAIM_PERIOD, "Claim period not ended yet");
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }
}