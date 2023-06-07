// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity ^0.8.0;

interface IControlCenter {
    function onlyOperator(address account) external view;

    function onlyTreasurer(address account) external view;

    function onlyModerator(address account) external view;

    /*
    //////////////////////
      WHITELIST FUNTIONS  
    //////////////////////
    */

    function whitelisting(address account) external view returns (bool);

    function onlyWhitelisted(address account) external view;

    function addToWhitelist(address account) external;

    function removeFromWhitelist(address account) external;

    function addMultiToWhitelist(address[] calldata accounts) external;

    function removeMultiFromWhitelist(address[] calldata accounts) external;

    /*
    //////////////////////
      BLACKLIST FUNTIONS  
    //////////////////////
    */

    function blacklisting(address account) external view returns (bool);

    function notInBlacklisted(address account) external view;

    function addToBlacklist(address account) external;

    function removeFromBlacklist(address account) external;

    function addMultiToBlacklist(address[] calldata accounts) external;

    function removeMultiFromBlacklist(address[] calldata accounts) external;
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/access/IControlCenter.sol";

/**
 * @title A place for common modifiers and functions used by various Markets, if any.
 * @dev This also leaves a gap which can be used to add a new Market to the top of the inheritance tree.
 */
abstract contract MarketCore is Pausable {
    IControlCenter public immutable controlCenter;
    address public immutable treasury;
    uint public constant PERCENTAGE = 10000; // x100 percent precision (100.00%)
    uint public serviceFeePercent;
    uint public deliveryDuration;
    // uint public reimbursementFeePercent;

    mapping(address => bool) public isPaymentToken;

    event RescuesTokenStuck(address token, uint256 amount);
    event UpdatePaymentToken(address token, bool isAllowed);
    event UpdateReimbursementFee(uint oldFee, uint newFee);
    event UpdateServiceFeePercent(uint oldFee, uint newFee);
    event UpdateDeliveryDuration(uint oldDuration, uint newDuration);

    constructor(IControlCenter _controlCenter, address _treasury) {
        controlCenter = _controlCenter;
        treasury = _treasury;
        serviceFeePercent = 125; // 1.25%
        deliveryDuration = 30 days;
        // reimbursementFeePercent = 500; // 5.00%
    }

    modifier onlyModerator() {
        controlCenter.onlyModerator(_msgSender());
        _;
    }

    modifier onlyTreasurer() {
        controlCenter.onlyTreasurer(_msgSender());
        _;
    }

    function updatePaymentToken(
        address token,
        bool isAllowed
    ) external onlyTreasurer {
        isPaymentToken[token] = isAllowed;
        emit UpdatePaymentToken(token, isAllowed);
    }

    function updateServiceFeePercent(uint percent) external onlyTreasurer {
        require(percent < PERCENTAGE, "MarketCore: FEE_TOO_HIGH");
        emit UpdateServiceFeePercent(serviceFeePercent, percent);
        serviceFeePercent = percent;
    }

    // function setReimbursementFeePercent(uint percent) external onlyTreasurer {
    //     emit UpdateReimbursementFee(reimbursementFeePercent, percent);
    //     reimbursementFeePercent = percent;
    // }

    function updateDeliveryDuration(uint newDuration) external onlyModerator {
        emit UpdateDeliveryDuration(deliveryDuration, newDuration);
        deliveryDuration = newDuration;
    }

    function pause() public onlyModerator {
        _pause();
    }

    function unpause() external onlyModerator {
        _unpause();
    }

    /**
     * @dev Rescue random funds stuck can't handle.
     * @param token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address token) external onlyTreasurer {
        require(!isPaymentToken[token], "MarketCore: STUCK_TOKEN_ONLY");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, amount);
        emit RescuesTokenStuck(token, amount);
    }

    // Confirmation required for receiving ERC721 to smart contract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

/**
 * @title Allows the owner of an NFT to listed item.
 * @dev NFTs are escrowed in the market contract.
 */

abstract contract MarketItem {
    /**
     * @notice The listing configuration for a specific NFT.
     */
    struct ItemListing {
        /**
         * @notice The owner of the NFT which listed it in auction.
         */
        address seller;
        /**
         * @notice Is this NFT listing for fixed price?
         */
        bool isFixedPrice;
        /**
         * @notice Is this NFT required shipping?
         */
        bool isRequiredShipping;
        /**
         * @notice The time at which this auction will accept new bids.
         */
        uint256 startTime;
        /**
         * @notice The time at which this auction will not accept any new bids.
         * @dev This is `0` until the first bid is placed.
         */
        uint256 endTime;
        /**
         * @notice The current highest bidder in this auction.
         * @dev This is `address(0)` until the first bid is placed.
         */
        address buyer;
        /**
         * @notice The address of the token payment contract for this NFT.
         */
        address paymentToken;
        /**
         * @notice The latest price of the NFT in this auction.
         * @dev This is set to the starting price, and then to the lowest bid once the auction has started.
         * If there is does not receive any bids greater than starting price, the auction will end without a sale.
         */
        uint256 amount;
        /**
         * @notice The minimum price gap between two bids
         * @dev Must greater than 1. The next highest bid >= highest bid + gap.
         */
        // uint256 gap;
    }

    /**
     * @notice Stores the auction for each NFT.
     * @dev NFT contract address => tokenId => ItemListing
     */
    mapping(address => mapping(uint256 => ItemListing)) public itemListing;

    event Listing(address nftContract, uint256 tokenId, ItemListing item);

    event Bidded(
        address nftContract,
        uint256 tokenId,
        address buyer,
        uint256 amount
    );

    event UpdateItemListing(
        address nftContract,
        uint256 tokenId,
        ItemListing item
    );

    event RemoveItemListing(address nftContract, uint256 tokenId);

    /**
     * @notice List an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param _item The ListPrice struct of the NFT.
     */
    function _listingItem(
        address nftContract,
        uint256 tokenId,
        ItemListing memory _item
    ) internal {
        require(_item.startTime > block.timestamp, "MarketItem: STARTED");
        require(
            (_item.startTime + 10 minutes) <= _item.endTime,
            "MarketItem: INVALID_END_TIME"
        );
        // require(_item.gap > 0, "MarketItem: GAP_ZERO");
        itemListing[nftContract][tokenId] = _item;
        emit Listing(nftContract, tokenId, _item);
    }

    /**
     * @notice Update the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param buyer Who bid for this NFT.
     * @param amount The price at which bidder offering for this NFT.
     */
    function _bidding(
        address nftContract,
        uint256 tokenId,
        address buyer,
        uint256 amount
    ) internal {
        ItemListing storage _item = itemListing[nftContract][tokenId];

        require(_item.startTime < block.timestamp, "MarketItem: NOT_STARTED");
        require(_item.endTime > block.timestamp, "MarketItem: AUCTION_ENDED");
        require(
            // _item.amount + _item.gap <= amount,
            _item.amount < amount,
            "MarketItem: AMOUNT_TOO_LOW"
        );

        _item.buyer = buyer;
        _item.amount = amount;

        emit Bidded(nftContract, tokenId, buyer, amount);
    }

    /**
     * @notice Update for an NFT listed.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     */
    function _updateItemListing(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount
    ) internal {
        ItemListing storage _item = itemListing[nftContract][tokenId];

        if (!_item.isFixedPrice) {
            require(
                block.timestamp < _item.startTime ||
                    block.timestamp > _item.endTime,
                "MarketItem: LISTING"
            );
        }
        // require(gap > 0, "MarketItem: GAP_ZERO");

        _item.startTime = startTime;
        _item.endTime = endTime;
        _item.paymentToken = paymentToken;
        _item.amount = amount;

        emit UpdateItemListing(nftContract, tokenId, _item);
    }

    /**
     * @notice Remove an NFT listed.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     */
    function _removeItemListing(address nftContract, uint256 tokenId) internal {
        ItemListing storage _item = itemListing[nftContract][tokenId];
        if (!_item.isFixedPrice) {
            require(
                block.timestamp < _item.startTime ||
                    block.timestamp > _item.endTime,
                "MarketItem: LISTING"
            );
        }
        delete itemListing[nftContract][tokenId];
        emit RemoveItemListing(nftContract, tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/access/IControlCenter.sol";
import "./MarketCore.sol";
import "./MarketItem.sol";

/**
 * @title Finentic Marketplace.
 */

contract Marketplace is MarketItem, MarketCore {
    using Counters for Counters.Counter;

    enum ShippingState {
        Cancelled,
        Sold,
        Delivered
    }

    struct ItemShipping {
        ShippingState state;
        uint256 nextUpdateDeadline;
    }

    event ShippingUpdated(
        address nftContract,
        uint256 tokenId,
        ShippingState state,
        uint256 nextUpdateDeadline
    );

    event Invoice(
        address nftContract,
        uint256 tokenId,
        address buyer,
        address seller,
        address paymentToken,
        uint256 costs
    );

    /**
     * @notice Stores the current shipping state for each NFT.
     * @dev NFT contract address => token Id => ItemShipping
     */
    mapping(address => mapping(uint256 => ItemShipping)) public itemShipping;

    constructor(
        IControlCenter _controlCenter,
        address _treasury
    ) MarketCore(_controlCenter, _treasury) {}

    /**
     * @notice Sets the fixed price for an NFT and escrows it in the market contract.
     * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
     * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param isFixedPrice Is this NFT listing for fixed price?
     * @param isRequiredShipping Is this NFT required shipping?
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     */
    function listForSale(
        address nftContract,
        uint256 tokenId,
        bool isFixedPrice,
        bool isRequiredShipping,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount
    ) external whenNotPaused {
        require(
            isPaymentToken[paymentToken],
            "Marketplace: PAYMENT_UNACCEPTED"
        );
        IERC721(nftContract).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        ItemListing memory _itemListing = ItemListing(
            _msgSender(),
            isFixedPrice,
            isRequiredShipping,
            startTime,
            endTime,
            address(0),
            paymentToken,
            amount
        );
        _listingItem(nftContract, tokenId, _itemListing);
    }

    function buyItemFixedPrice(
        address nftContract,
        uint256 tokenId
    ) external whenNotPaused {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(_itemListing.isFixedPrice, "Marketplace: AUCTION_ITEM");
        require(
            _itemListing.startTime < block.timestamp,
            "Marketplace: NOT_STARTED"
        );
        require(_itemListing.endTime > block.timestamp, "Marketplace: ENDED");
        require(_itemListing.buyer == address(0), "Marketplace: SOLD");

        IERC20 _paymentToken = IERC20(_itemListing.paymentToken);
        _paymentToken.transferFrom(
            _msgSender(),
            address(this),
            _itemListing.amount
        );

        if (!_itemListing.isRequiredShipping) {
            return _takeOwnItem(nftContract, tokenId);
        }

        itemListing[nftContract][tokenId].buyer = _msgSender();
        uint256 nextUpdateDeadline = block.timestamp + deliveryDuration;
        itemShipping[nftContract][tokenId] = ItemShipping(
            ShippingState.Sold,
            nextUpdateDeadline
        );

        emit ShippingUpdated(
            nftContract,
            tokenId,
            ShippingState.Sold,
            nextUpdateDeadline
        );
    }

    function bidding(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(!_itemListing.isFixedPrice, "Marketplace: FIXED_PRICE_ITEM");

        IERC20 _paymentToken = IERC20(_itemListing.paymentToken);
        _paymentToken.transferFrom(_msgSender(), address(this), amount);
        if (_itemListing.buyer != address(0)) {
            _paymentToken.transfer(_itemListing.buyer, _itemListing.amount);
        }
        _bidding(nftContract, tokenId, _msgSender(), amount);
    }

    function paymentProcessing(address nftContract, uint256 tokenId) external {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(_itemListing.buyer == _msgSender(), "Marketplace: FORBIDDEN");
        require(!_itemListing.isFixedPrice, "Marketplace: FIXED_PRICE_ITEM");

        if (!_itemListing.isRequiredShipping) {
            return _takeOwnItem(nftContract, tokenId);
        }

        uint256 nextUpdateDeadline = block.timestamp + deliveryDuration;
        itemShipping[nftContract][tokenId] = ItemShipping(
            ShippingState.Sold,
            nextUpdateDeadline
        );

        emit ShippingUpdated(
            nftContract,
            tokenId,
            ShippingState.Sold,
            nextUpdateDeadline
        );
    }

    function confirmReceivedItem(
        address nftContract,
        uint256 tokenId
    ) external {
        ItemShipping memory _itemShipping = itemShipping[nftContract][tokenId];
        require(
            _itemShipping.state == ShippingState.Sold,
            "Marketplace: UNSOLD"
        );
        require(
            _itemShipping.nextUpdateDeadline > block.timestamp,
            "Marketplace: OVERDUE"
        );
        require(
            itemListing[nftContract][tokenId].buyer == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        _takeOwnItem(nftContract, tokenId);
        delete itemShipping[nftContract][tokenId];
        emit ShippingUpdated(nftContract, tokenId, ShippingState.Delivered, 0);
    }

    /**
     * @notice Update the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     */
    function updateItemListing(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount
    ) external {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(_itemListing.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemListing.buyer == address(0), "Marketplace: SOLD");
        require(
            isPaymentToken[paymentToken],
            "Marketplace: PAYMENT_UNACCEPTED"
        );
        _updateItemListing(
            nftContract,
            tokenId,
            startTime,
            endTime,
            paymentToken,
            amount
        );
    }

    function cancelItemDelivering(
        address nftContract,
        uint256 tokenId
    ) external {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(
            _itemListing.buyer == _msgSender() ||
                _itemListing.seller == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        require(
            itemShipping[nftContract][tokenId].state == ShippingState.Sold,
            "Marketplace: UNSOLD"
        );
        IERC20(_itemListing.paymentToken).transfer(
            _itemListing.buyer,
            _itemListing.amount
        );
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemListing.seller,
            tokenId
        );
        _removeItemListing(nftContract, tokenId);
        delete itemShipping[nftContract][tokenId];
        emit ShippingUpdated(nftContract, tokenId, ShippingState.Cancelled, 0);
    }

    function cancelListItem(address nftContract, uint256 tokenId) external {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        require(_itemListing.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemListing.buyer == address(0), "Marketplace: SOLD");

        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemListing.seller,
            tokenId
        );
        _removeItemListing(nftContract, tokenId);
    }

    function _takeOwnItem(address nftContract, uint256 tokenId) internal {
        ItemListing memory _itemListing = itemListing[nftContract][tokenId];
        IERC20 _paymentToken = IERC20(_itemListing.paymentToken);

        uint256 serviceFee = (_itemListing.amount * serviceFeePercent) /
            PERCENTAGE;

        _paymentToken.transfer(
            _itemListing.seller,
            _itemListing.amount - serviceFee
        );

        _paymentToken.transfer(treasury, serviceFee);

        IERC721(nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );

        _removeItemListing(nftContract, tokenId);
    }
}