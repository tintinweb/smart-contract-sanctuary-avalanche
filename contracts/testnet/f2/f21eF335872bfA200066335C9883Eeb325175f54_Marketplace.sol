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

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @dev NFTs in auction are escrowed in the market contract.
 */

abstract contract MarketAuction {
    /**
     * @notice The auction configuration for a specific NFT.
     */
    struct ItemAuction {
        /**
         * @notice The owner of the NFT which listed it in auction.
         */
        address seller;
        /**
         * @notice Is this NFT linked to a physical asset?
         */
        bool isPhygital;
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
        address bidder;
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
        uint256 gap;
    }

    /**
     * @notice Stores the auction for each NFT.
     * @dev NFT contract address => token Id => ItemAuction
     */
    mapping(address => mapping(uint256 => ItemAuction)) public itemAuction;

    event ListForAuction(
        address nftContract,
        uint256 tokenId,
        ItemAuction _itemAuction
    );

    event BiddingForAuction(
        address nftContract,
        uint256 tokenId,
        address bidder,
        uint256 amount
    );

    event UpdateItemForAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount,
        uint256 gap
    );

    event RemoveItemForAuction(address nftContract, uint256 tokenId);

    /**
     * @notice Sets the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param _itemAuction The ListPrice struct of the NFT.
     */
    function _setItemForAuction(
        address nftContract,
        uint256 tokenId,
        ItemAuction memory _itemAuction
    ) internal {
        require(
            _itemAuction.startTime > block.timestamp,
            "MarketAuction: AUCTION_STARTED"
        );
        require(
            (_itemAuction.startTime + 1 hours) < _itemAuction.endTime,
            "MarketAuction: INVALID_END_TIME"
        );
        require(_itemAuction.gap > 0, "MarketAuction: GAP_ZERO");
        itemAuction[nftContract][tokenId] = _itemAuction;
        emit ListForAuction(nftContract, tokenId, _itemAuction);
    }

    function _biddingForAuction(
        address nftContract,
        uint256 tokenId,
        address bidder,
        uint256 amount
    ) internal {
        ItemAuction memory _itemAuction = itemAuction[nftContract][tokenId];
        require(
            _itemAuction.startTime < block.timestamp,
            "MarketAuction: NOT_STARTED"
        );
        require(
            _itemAuction.endTime > block.timestamp,
            "MarketAuction: AUCTION_ENDED"
        );
        require(
            _itemAuction.amount + _itemAuction.gap <= amount,
            "MarketAuction: AMOUNT_TOO_LOW"
        );

        itemAuction[nftContract][tokenId].bidder = bidder;
        itemAuction[nftContract][tokenId].amount = amount;

        emit BiddingForAuction(nftContract, tokenId, bidder, amount);
    }

    /**
     * @notice Update the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     * @param gap The minimum price gap between two bids
     */
    function _updateItemForAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount,
        uint256 gap
    ) internal {
        ItemAuction storage _itemAuction = itemAuction[nftContract][tokenId];
        require(gap > 0, "MarketAuction: GAP_ZERO");
        _itemAuction.startTime = startTime;
        _itemAuction.endTime = endTime;
        _itemAuction.paymentToken = paymentToken;
        _itemAuction.amount = amount;
        _itemAuction.gap = gap;
        emit UpdateItemForAuction(
            nftContract,
            tokenId,
            startTime,
            endTime,
            paymentToken,
            amount,
            gap
        );
    }

    /**
     * @notice Remove the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     */
    function _removeItemForAuction(
        address nftContract,
        uint256 tokenId
    ) internal {
        ItemAuction storage _itemAuction = itemAuction[nftContract][tokenId];
        require(
            _itemAuction.startTime > block.timestamp ||
                _itemAuction.endTime < block.timestamp,
            "MarketAuction: AUCTION_ACTIVE"
        );
        delete itemAuction[nftContract][tokenId];
        emit RemoveItemForAuction(nftContract, tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

/**
 * @title Allows sellers to set a list price of their NFTs that may be accepted and instantly transferred to the buyer.
 * @notice NFTs with a list price set are escrowed in the market contract.
 */

abstract contract MarketBuyNow {
    /**
     * @notice Stores the list price details for a specific NFT.
     */
    struct ItemBuyNow {
        /**
         * @notice The current owner of this NFT which set a list price.
         */
        address seller;
        /**
         * @notice The new owner of this NFT which purchase.
         */
        address buyer;
        /**
         * @notice Is this NFT linked to a physical asset?
         */
        bool isPhygital;
        /**
         * @notice The address of the token payment contract for this NFT.
         */
        address paymentToken;
        /**
         * @notice The current buy price set for this NFT.
         * @dev A zero price is acceptable so a non-zero address determines whether a price has been set.
         */
        uint256 price;
    }

    /**
     * @notice Stores the current list price for each NFT.
     * @dev NFT contract address => token Id => ItemBuyNow
     */
    mapping(address => mapping(uint256 => ItemBuyNow)) public itemBuyNow;

    event ListForBuyNow(
        address nftContract,
        uint tokenId,
        address seller,
        bool isPhygital,
        address paymentToken,
        uint256 price
    );

    event UpdateItemForBuyNow(
        address nftContract,
        uint tokenId,
        address paymentToken,
        uint256 price
    );

    event RemoveItemForBuyNow(address nftContract, uint tokenId);

    /**
     * @notice Sets the list price for an NFT.
     * @dev A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param _itemBuyNow The ItemBuyNow struct of the NFT.
     */
    function _setItemForBuyNow(
        address nftContract,
        uint256 tokenId,
        ItemBuyNow memory _itemBuyNow
    ) internal {
        itemBuyNow[nftContract][tokenId] = _itemBuyNow;
        emit ListForBuyNow(
            nftContract,
            tokenId,
            _itemBuyNow.seller,
            _itemBuyNow.isPhygital,
            _itemBuyNow.paymentToken,
            _itemBuyNow.price
        );
    }

    /**
     * @notice Update the list price for an NFT.
     * @dev A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param price The price at which someone could buy this NFT.
     */
    function _updateItemForBuyNow(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price
    ) internal {
        ItemBuyNow storage _itemBuyNow = itemBuyNow[nftContract][tokenId];
        _itemBuyNow.paymentToken = paymentToken;
        _itemBuyNow.price = price;
        emit UpdateItemForBuyNow(nftContract, tokenId, paymentToken, price);
    }

    /**
     * @notice Remove the list price for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     */
    function _removeItemForBuyNow(
        address nftContract,
        uint256 tokenId
    ) internal {
        delete itemBuyNow[nftContract][tokenId];
        emit RemoveItemForBuyNow(nftContract, tokenId);
    }
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
    // uint public reimbursementFeePercent;
    uint public deliveryDuration;

    mapping(address => bool) public isPaymentToken;

    event RescuesTokenStuck(address token, uint256 amount);
    event UpdatePaymentToken(address token, bool isAllowed);
    event UpdateReimbursementFee(uint oldFee, uint newFee);
    event UpdateServiceFeePercent(uint oldFee, uint newFee);
    event UpdateDeliveryDuration(uint oldDuration, uint newDuration);

    constructor(IControlCenter _controlCenter, address _treasury) {
        controlCenter = _controlCenter;
        treasury = _treasury;
        serviceFeePercent = 1; // 0.01%
        // reimbursementFeePercent = 500; // 5.00%
        deliveryDuration = 2 weeks;
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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/access/IControlCenter.sol";
import "./MarketCore.sol";
import "./MarketBuyNow.sol";
import "./MarketAuction.sol";

/**
 * @title Finentic Marketplace.
 */

contract Marketplace is MarketBuyNow, MarketAuction, MarketCore {
    using Counters for Counters.Counter;

    enum PhygitalItemState {
        Cancelled,
        Sold,
        Delivered
    }

    struct PhygitalItem {
        PhygitalItemState state;
        uint256 nextUpdateDeadline;
    }

    event PhygitalItemUpdated(
        address nftContract,
        uint256 tokenId,
        PhygitalItemState state,
        uint256 nextUpdateDeadline
    );

    event Invoice(
        address indexed buyer,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 costs
    );

    /**
     * @notice Stores the current list price for each NFT.
     * @dev NFT contract address => token Id => ListPrice
     */
    mapping(address => mapping(uint256 => PhygitalItem)) public phygitalItem;

    constructor(
        IControlCenter _controlCenter,
        address _treasury
    ) MarketCore(_controlCenter, _treasury) {}

    /**
     * @notice Sets the list price for an NFT and escrows it in the market contract.
     * A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
     * @dev If there is an offer for this amount or higher, that will be accepted instead of setting a buy price.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param isPhygital Is this NFT linked to a physical asset?
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param price The price at which someone could buy this NFT.
     */
    function listForBuyNow(
        address nftContract,
        uint256 tokenId,
        bool isPhygital,
        address paymentToken,
        uint256 price
    ) external whenNotPaused {
        require(isPaymentToken[paymentToken], "Marketplace: UNACCEPTED_TOKEN");
        IERC721(nftContract).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        ItemBuyNow memory _itemBuyNow = ItemBuyNow(
            _msgSender(),
            address(0),
            isPhygital,
            paymentToken,
            price
        );
        _setItemForBuyNow(nftContract, tokenId, _itemBuyNow);
    }

    function buyNow(
        address nftContract,
        uint256 tokenId
    ) external whenNotPaused {
        ItemBuyNow memory _itemBuyNow = itemBuyNow[nftContract][tokenId];
        require(_itemBuyNow.buyer == address(0), "Marketplace: SOLD");
        IERC20 _paymentToken = IERC20(_itemBuyNow.paymentToken);
        _paymentToken.transferFrom(
            _msgSender(),
            address(this),
            _itemBuyNow.price
        );
        emit Invoice(
            _msgSender(),
            _itemBuyNow.seller,
            nftContract,
            tokenId,
            _itemBuyNow.paymentToken,
            _itemBuyNow.price
        );
        if (!_itemBuyNow.isPhygital) {
            return _takeOwnItemBuyNow(nftContract, tokenId);
        }
        itemBuyNow[nftContract][tokenId].buyer = _msgSender();
        uint256 nextUpdateDeadline = block.timestamp + deliveryDuration;
        phygitalItem[nftContract][tokenId] = PhygitalItem(
            PhygitalItemState.Sold,
            nextUpdateDeadline
        );
        emit Invoice(
            _msgSender(),
            _itemBuyNow.seller,
            nftContract,
            tokenId,
            _itemBuyNow.paymentToken,
            _itemBuyNow.price
        );
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Sold,
            nextUpdateDeadline
        );
    }

    function confirmReceivedItemBuyNow(
        address nftContract,
        uint256 tokenId
    ) external {
        PhygitalItem memory _phygitalItem = phygitalItem[nftContract][tokenId];
        require(
            _phygitalItem.state == PhygitalItemState.Sold,
            "Marketplace: UNSOLD"
        );
        require(
            _phygitalItem.nextUpdateDeadline > block.timestamp,
            "Marketplace: OVERDUE"
        );
        require(
            itemBuyNow[nftContract][tokenId].buyer == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        _takeOwnItemBuyNow(nftContract, tokenId);
        delete phygitalItem[nftContract][tokenId];
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Delivered,
            0
        );
    }

    function cancelItemBuyNow(address nftContract, uint256 tokenId) external {
        ItemBuyNow memory _itemBuyNow = itemBuyNow[nftContract][tokenId];
        require(
            _itemBuyNow.buyer == _msgSender() ||
                _itemBuyNow.seller == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        require(
            phygitalItem[nftContract][tokenId].state == PhygitalItemState.Sold,
            "Marketplace: UNSOLD"
        );
        IERC20(_itemBuyNow.paymentToken).transfer(
            _itemBuyNow.buyer,
            _itemBuyNow.price
        );
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemBuyNow.seller,
            tokenId
        );
        _removeItemForBuyNow(nftContract, tokenId);
        delete phygitalItem[nftContract][tokenId];
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Cancelled,
            0
        );
    }

    /**
     * @notice Update the list price for an NFT.
     * @dev A 0 price is acceptable and valid price you can set, enabling a giveaway to the first collector that calls `buy`.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param price The price at which someone could buy this NFT.
     */
    function updateItemForBuyNow(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price
    ) external {
        ItemBuyNow memory _itemBuyNow = itemBuyNow[nftContract][tokenId];
        require(_itemBuyNow.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemBuyNow.buyer == address(0), "Marketplace: SOLD");
        require(isPaymentToken[paymentToken], "Marketplace: UNACCEPTED_TOKEN");
        _updateItemForBuyNow(nftContract, tokenId, paymentToken, price);
    }

    function cancelListItemForBuyNow(
        address nftContract,
        uint256 tokenId
    ) external {
        ItemBuyNow memory _itemBuyNow = itemBuyNow[nftContract][tokenId];
        require(_itemBuyNow.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemBuyNow.buyer == address(0), "Marketplace: SOLD");
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemBuyNow.seller,
            tokenId
        );
        _removeItemForBuyNow(nftContract, tokenId);
    }

    function _takeOwnItemBuyNow(address nftContract, uint256 tokenId) internal {
        ItemBuyNow memory _itemBuyNow = itemBuyNow[nftContract][tokenId];
        IERC20 _paymentToken = IERC20(_itemBuyNow.paymentToken);
        uint256 serviceFee = (_itemBuyNow.price * serviceFeePercent) /
            PERCENTAGE;
        _paymentToken.transfer(
            _itemBuyNow.seller,
            _itemBuyNow.price - serviceFee
        );
        _paymentToken.transfer(treasury, serviceFee);
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );
        _removeItemForBuyNow(nftContract, tokenId);
    }

    /**
     * @notice Add the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param isPhygital Is this NFT linked to a physical asset?
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     * @param gap The minimum price gap between two bids
     */
    function listForAuction(
        address nftContract,
        uint256 tokenId,
        bool isPhygital,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount,
        uint256 gap
    ) external whenNotPaused {
        require(isPaymentToken[paymentToken], "Marketplace: UNACCEPTED_TOKEN");
        ItemAuction memory _itemAuction = ItemAuction(
            _msgSender(),
            isPhygital,
            startTime,
            endTime,
            address(0),
            paymentToken,
            amount,
            gap
        );
        IERC721(nftContract).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        _setItemForAuction(nftContract, tokenId, _itemAuction);
    }

    function biddingForAuction(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external {
        ItemAuction memory _itemAuction = itemAuction[nftContract][tokenId];
        IERC20 _paymentToken = IERC20(_itemAuction.paymentToken);
        _paymentToken.transferFrom(_msgSender(), address(this), amount);
        if (_itemAuction.bidder != address(0)) {
            _paymentToken.transfer(_itemAuction.bidder, _itemAuction.amount);
        }
        _biddingForAuction(nftContract, tokenId, _msgSender(), amount);
    }

    function paymentProcessingItemAuction(
        address nftContract,
        uint256 tokenId
    ) external {
        ItemAuction memory _itemAuction = itemAuction[nftContract][tokenId];
        require(_itemAuction.bidder == _msgSender(), "Marketplace: FORBIDDEN");
        emit Invoice(
            _msgSender(),
            _itemAuction.seller,
            nftContract,
            tokenId,
            _itemAuction.paymentToken,
            _itemAuction.amount
        );
        if (!_itemAuction.isPhygital) {
            return _takeOwnItemAuction(nftContract, tokenId);
        }
        uint256 nextUpdateDeadline = block.timestamp + deliveryDuration;
        phygitalItem[nftContract][tokenId] = PhygitalItem(
            PhygitalItemState.Sold,
            nextUpdateDeadline
        );
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Sold,
            nextUpdateDeadline
        );
    }

    function confirmReceivedItemAuction(
        address nftContract,
        uint256 tokenId
    ) external {
        PhygitalItem memory _phygitalItem = phygitalItem[nftContract][tokenId];
        require(
            itemAuction[nftContract][tokenId].bidder == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        require(
            _phygitalItem.state == PhygitalItemState.Sold,
            "Marketplace: UNSOLD"
        );
        require(
            _phygitalItem.nextUpdateDeadline > block.timestamp,
            "Marketplace: OVERDUE"
        );
        _takeOwnItemAuction(nftContract, tokenId);
        delete phygitalItem[nftContract][tokenId];
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Sold,
            0
        );
    }

    function _takeOwnItemAuction(
        address nftContract,
        uint256 tokenId
    ) internal {
        ItemAuction memory _itemAuction = itemAuction[nftContract][tokenId];
        IERC20 _paymentToken = IERC20(_itemAuction.paymentToken);
        uint256 serviceFee = (_itemAuction.amount * serviceFeePercent) /
            PERCENTAGE;
        _paymentToken.transfer(
            _itemAuction.seller,
            _itemAuction.amount - serviceFee
        );
        _paymentToken.transfer(treasury, serviceFee);
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );
        _removeItemForAuction(nftContract, tokenId);
    }

    function cancelItemAuction(address nftContract, uint256 tokenId) external {
        ItemAuction memory _itemAuction = itemAuction[nftContract][tokenId];
        require(
            _itemAuction.bidder == _msgSender() ||
                _itemAuction.seller == _msgSender(),
            "Marketplace: FORBIDDEN"
        );
        require(
            phygitalItem[nftContract][tokenId].state == PhygitalItemState.Sold,
            "Marketplace: UNSOLD"
        );
        IERC20(_itemAuction.paymentToken).transfer(
            _itemAuction.bidder,
            _itemAuction.amount
        );
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemAuction.seller,
            tokenId
        );
        _removeItemForAuction(nftContract, tokenId);
        delete phygitalItem[nftContract][tokenId];
        emit PhygitalItemUpdated(
            nftContract,
            tokenId,
            PhygitalItemState.Cancelled,
            0
        );
    }

    /**
     * @notice Update the auction for an NFT.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will accept new bids.
     * @param endTime The time at which this auction will not accept any new bids.
     * @param paymentToken The address of the token payment contract for this NFT.
     * @param amount The price at which someone could buy this NFT.
     * @param gap The minimum price gap between two bids
     */
    function updateItemForAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        address paymentToken,
        uint256 amount,
        uint256 gap
    ) external {
        ItemAuction storage _itemAuction = itemAuction[nftContract][tokenId];
        require(_itemAuction.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemAuction.bidder == address(0), "Marketplace: SOLD");
        require(isPaymentToken[paymentToken], "Marketplace: UNACCEPTED_TOKEN");
        _updateItemForAuction(
            nftContract,
            tokenId,
            startTime,
            endTime,
            paymentToken,
            amount,
            gap
        );
    }

    function cancelListItemForAuction(
        address nftContract,
        uint256 tokenId
    ) external {
        ItemAuction storage _itemAuction = itemAuction[nftContract][tokenId];
        require(_itemAuction.seller == _msgSender(), "Marketplace: FORBIDDEN");
        require(_itemAuction.bidder == address(0), "Marketplace: SOLD");
        IERC721(nftContract).safeTransferFrom(
            address(this),
            _itemAuction.seller,
            tokenId
        );
        _removeItemForAuction(nftContract, tokenId);
    }
}