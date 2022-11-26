/**
 *Submitted for verification at snowtrace.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
// veCASH by xrpant modified from vePtpV2

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.8.0;
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
    mapping(address => uint256) _balances;

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

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 10**18;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }
}

interface ILPFarm {
    function bCashView(address) external view returns(uint);
}

interface IPapilio {
    function ownerOf(uint256) external view returns(address);
    function stakeNFT(uint256) external;
    function unStakeNFT(uint256) external;
    function tokenStaked(uint256) external view returns(bool);
    function tokensOfOwner(address) external view returns(uint[] memory);
}

pragma solidity ^0.8.7;

/// @title VeCASH
/// @notice Vote-Escrow CASH: the staking contract for bCASH, as well as the token used for governance.
/// Allows depositing/withdraw of bCASH
/// Here are the rules of the game:
/// If you stake bCASH in this contract, or if you stake LP tokens in the farms
/// you generate veCASH at the current `generationRate` until you reach `maxCap`
/// If you unstake any amount of bCASH, you loose all of your veCASH.
/// If you hold Papilio Palatia NFTs you will get a 'nftMultiplier' boost that stacks
/// up to the 'maxNFT' number of NFTs.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once bCASH is sufficiently
/// distributed and the community can govern itself.
contract veCASH is ERC20, Ownable, ReentrancyGuard {

    struct UserInfo {
        uint256 amount; // bCASH staked by user
        uint256 lastRelease; // time of last veCASH claim or first deposit if user has not claimed yet
        uint256[] stakedNFTs; // tokenIds of staked NFTs
    }

    /// @notice the NFT contract
    IPapilio public _nft;

    /// @notice the bCASH contract
    IERC20 public _bc;

    /// @notice the LP Farm contracts
    ILPFarm public _farm1;
    ILPFarm public _farm2;

    /// @notice max veCASH to staked ptp ratio
    /// Note if user has 10 bCASH staked, they can only have a max of 10 * maxCap veCASH in balance
    uint256 public maxCap;

    /// @notice the rate of veCASH generated per second, per bCASH staked
    uint256 public generationRate;

    /// @notice the multiplier provided by each Papilio NFT held by staker
    uint256 public nftMultiplier;

    /// @notice the max number of NFTs that can provide a stacked multiplier
    uint256 public maxNFT;

    /// @notice user info mapping
    mapping(address => UserInfo) public users;

    /// @notice staker to index in 'stakers' array
    mapping(address => uint256) public stakerToIndex;

    // amounts of bCASH that need to be staked for each tier
    uint256[7] public tierLevels;

    // accumulation multiplier for each tier
    uint256[7] public tierMultiplier;

    // list of all stakers
    address[] private stakers;

    /// @notice events describing staking, unstaking and claiming
    event Staked(address indexed user, uint256 indexed amount);
    event Unstaked(address indexed user, uint256 indexed amount);
    event Claimed(address indexed user, uint256 indexed amount);
    event StakedNFT(address indexed owner, uint256 indexed tokenId);
    event UnStakedNFT(address indexed owner, uint256 indexed tokenId);

    bool private allowTransfer = false;
    bool public paused = false;

    constructor() ERC20("Vote-Escrow Cash", "veCASH") {
        _bc = IERC20(0x4BA16DaF8ed418deD920C66e45cc3eaFFDE53Ac7);
        _nft = IPapilio(0xe80E87F412D2cC73045b73EF7e07A47ef0A41Cc0);
        _farm1 = ILPFarm(0x33B9da3bc122219C1B8ed484C6DB7f2D6c6d82C3);
        _farm2 = ILPFarm(0x058184ADde5426c5c6d11ad41eCb8f42EB704002);
        generationRate = 3888888888888; // veCASH generation per second. 0.014/hr
        maxCap = 100;
        // amounts user must stake to reach each tier
        tierLevels = [1 ether, 16667 ether, 33334 ether, 50000 ether, 66667 ether, 83333 ether, 100000 ether];
        // accrual multiplier given by each tier
        tierMultiplier = [0, 833, 1670, 2500, 3333, 4170, 5000];
        nftMultiplier = 500; // 5%
        maxNFT = 10;
    }

    /// @notice deposits bCASH
    /// @param _amount the amount of bCASH to stake
    function deposit(uint256 _amount) public nonReentrant {
        require(!paused, "Contract Paused!");
        require(_amount > 0, "amount to deposit cannot be zero");

        // request bCASH from user
        require(_bc.transferFrom(msg.sender, address(this), _amount), "Failed to transfer $bCASH!");

        if (isUser(msg.sender)) {
            // if user exists, first, claim his veCASH
            _claim(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
            stakerToIndex[msg.sender] = stakers.length;
            stakers.push(msg.sender);
        }

        // emit event
        emit Staked(msg.sender, _amount);

    }

    /// @notice withdraws staked bCASH
    /// @param _amount the amount of bCASH to unstake
    /// Note Beware! you will loose all of your veCASH if you unstake any amount of bCASH!
    /// Also if you withdraw everything it will unstake all your NFTs!
    function withdraw(uint256 _amount) external nonReentrant {
        require(!paused, "Contract Paused!");
        require(_amount > 0, "amount to withdraw cannot be zero");
        require(users[msg.sender].amount >= _amount, "not enough balance");

        // update balance and timestamp before burning or sending back bCASH
        users[msg.sender].amount -= _amount;
        users[msg.sender].lastRelease = block.timestamp;

        // if remaining amount is 0, unstake all NFTs
        if (users[msg.sender].amount == 0 && users[msg.sender].stakedNFTs.length > 0) {
            _unStakeAll(msg.sender);
            _removeStaker(msg.sender);
        }

        _burn(msg.sender, balanceOf(msg.sender));

        // send back the staked bCASH
        // SafeERC20 is not needed as PTP will revert if transfer fails
        _bc.transfer(msg.sender, _amount);

        // emit event
        emit Unstaked(msg.sender, _amount);
    }

    /// @notice claims accumulated veCASH
    function claim() external nonReentrant {
        require(!paused, "Contract Paused!");
        require(isUser(msg.sender), "user has no stake");
        _claim(msg.sender);
    }

    /// @notice Stake NFTs
    /// @param _tokenIds array of tokenIds to stake
    function stakeNFTs(uint256[] calldata _tokenIds) public nonReentrant {
        require(!paused, "Contract Paused!");
        require(users[msg.sender].amount > 0, "You have no stake!");
        // if user exists, first, claim his veCASH
        _claim(msg.sender);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_nft.ownerOf(_tokenIds[i]) == msg.sender, "You don't own that Papilio!");
            if (!_nft.tokenStaked(_tokenIds[i])) {
                _stake(msg.sender, _tokenIds[i]);
            }
        }
    }

    /// @notice Stake All NFTs
    /// Note will stake all user's NFTs
    function stakeAllNFTs() public nonReentrant {
        require(!paused, "Contract Paused!");
        require(users[msg.sender].amount > 0, "You have no stake!");
        // if user exists, first, claim his veCASH
        _claim(msg.sender);
        uint256[] memory _tokenIds = _nft.tokensOfOwner(msg.sender);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (!_nft.tokenStaked(_tokenIds[i])) {
                _stake(msg.sender, _tokenIds[i]);
            }
        }
    }

    /// @notice Unstake NFTs
    /// @param _tokenIds array of tokenIds to unstake
    function unStakeNFTs(uint256[] calldata _tokenIds) public nonReentrant {
        require(users[msg.sender].amount > 0, "You have no stake!");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_nft.tokenStaked(_tokenIds[i])) {
                _unStake(msg.sender, _tokenIds[i]);
            }
        }
    }

    /// @notice Unstake All NFTs
    /// Note will unstake all user's NFTs
    function unStakeAllNFTs() public nonReentrant {
        require(users[msg.sender].amount > 0, "You have no stake!");
        _unStakeAll(msg.sender);
    }

    // Private and Internal functions

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claim(address _addr) private {
        uint256 amount = _claimable(_addr);

        UserInfo storage user = users[_addr];

        // update last release time
        user.lastRelease = block.timestamp;

        if (amount > 0) {
            emit Claimed(_addr, amount);
            _mint(_addr, amount);
        }

    }

    /// @notice Calculate the amount of veCASH that can be claimed by user
    /// @dev private claimable function
    /// @param _addr the address to check
    /// @return amount of veCASH that can be claimed by user
    function _claimable(address _addr) private view returns (uint256 amount) {
        UserInfo storage user = users[_addr];

        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;

        // get bCASH user has staked in LP Farms
        // bCASH portion of LP staked is multiplied by 2
        uint256 totalLP = totalLpForUser(_addr);

        // calculate pending amount
        // Math.mwmul used to multiply wad numbers
        uint256 pending = Math.wmul((user.amount + totalLP), secondsElapsed * generationRate);

        // get user's vePTP balance
        uint256 userVeCashBalance = balanceOf(_addr);

        // user vePTP balance cannot go above user.amount * maxCap
        uint256 maxVeCashCap = user.amount * maxCap;

        // handle nft effects
        uint256 nfts = user.stakedNFTs.length;
        // user cannot stack more than 'maxNFT' multipliers
        if (nfts > maxNFT) {
            nfts = maxNFT;
        }

        // Calculate multipliers
        uint256 totalNftMultiplier = (nfts * nftMultiplier);

        uint256 userTier = tierFor(_addr);

        uint256 totalMultiplier;

        if (userTier > 0) {
            totalMultiplier = totalNftMultiplier + tierMultiplier[userTier - 1] + 10000;
        } else {
            totalMultiplier = totalNftMultiplier + 10000;
        }

        // apply multipler to pending amount
        pending = Math.wmul(pending, totalMultiplier);
        pending = Math.wdiv(pending, 10000);

        // first, check that user hasn't reached the max limit yet
        if (userVeCashBalance < maxVeCashCap) {
            // amount of veCASH to reach max cap
            uint256 amountToCap = maxVeCashCap - userVeCashBalance;

            // then, check if pending amount will make user balance overpass maximum amount
            if (pending >= amountToCap) {
                amount = amountToCap;
            } else {
                amount = pending;
            }
        } else {
            amount = 0;
        }
    }

    /// @notice Stake NFT
    /// @param _user user staking NFT
    /// @param _tokenId tokenId to stake
    function _stake(address _user, uint256 _tokenId) internal {
        _nft.stakeNFT(_tokenId);
        users[_user].stakedNFTs.push(_tokenId);
        emit StakedNFT(_user, _tokenId);
    }

    /// @notice Private Unstake All NFTs
    /// @param _user user unstaking NFT
    function _unStakeAll(address _user) internal {
        uint256[] memory _tokenIds = users[_user].stakedNFTs;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _unStake(_user, _tokenIds[i]);
        }
    }

    /// @notice Unstake NFT
    /// @param _user user unstaking NFT
    /// @param _tokenId tokenId to unstake
    function _unStake(address _user, uint256 _tokenId) internal {
        uint256[] memory _tokenIds = users[_user].stakedNFTs;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_tokenId == _tokenIds[i]) {
                users[_user].stakedNFTs[i] = users[_user].stakedNFTs[users[_user].stakedNFTs.length - 1];
                users[_user].stakedNFTs.pop();
                _nft.unStakeNFT(_tokenId);
                emit UnStakedNFT(_user, _tokenId);
            }
        }
    }

    /// @notice Remove staker from 'stakers' array
    /// @param _user user being removed
    function _removeStaker(address _user) internal {
        uint256 _userIndex = stakerToIndex[_user];
        address _lastStaker = stakers[stakers.length - 1];
        stakerToIndex[_lastStaker] = _userIndex;
        stakers[_userIndex] = _lastStaker;
        delete stakerToIndex[_user];
        stakers.pop();
    }

    // View functions

    /// @notice checks wether user _addr has bCASH staked
    /// @param _addr the user address to check
    /// @return true if the user has bCASH in stake, false otherwise
    function isUser(address _addr) public view returns (bool) {
        return users[_addr].amount > 0;
    }

    /// @notice returns staked amount of bCASH for user
    /// @param _addr the user address to check
    /// @return staked amount of bCASH
    function getStakedBCash(address _addr) public view returns (uint256) {
        return users[_addr].amount;
    }

    /// @notice Calculate the amount of veCASH that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of veCASH that can be claimed by user
    function claimable(address _addr) public view returns (uint256 amount) {
        require(_addr != address(0), "zero address");
        amount = _claimable(_addr);
    }

    /// @notice Calculate the amount of bCASH user has in LP Farms
    /// @param _addr the address to check
    /// @return amount of bCASH represented by staked LP tokens
    function totalLpForUser(address _addr) public view returns (uint256 amount) {
        uint256 lp1 = _farm1.bCashView(_addr);
        uint256 lp2 = _farm2.bCashView(_addr);
        // amount is multiplied by two to represent wavax portion as bCASH
        amount = (lp1 + lp2) * 2;
    }

    /// @notice Get the tier level for a user based on bCASH and LP staked/farmed
    /// @param _addr the address to check
    /// @return tier level of user
    function tierFor(address _addr) public view returns (uint256) {
        require(_addr != address(0), "zero address");
        uint256 amount = getStakedBCash(_addr) + totalLpForUser(_addr);

        for (uint256 i = 0; i < 7; i++) {
            if (amount < tierLevels[i]) {
                return i;
            }
        }

        return 7;
    }

    /// @notice Get the nft tokenIds a user has staked
    /// @param _user the address to check
    /// @return array of tokenIds
    function nftsStakedFor(address _user) public view returns(uint256[] memory) {
        return users[_user].stakedNFTs;
    }

    /// @notice Get an array of staker addresses
    /// Note the 0 index will be the contract address and should be ignored
    function getStakers() public view returns(address[] memory) {
        return stakers;
    }

    /// @notice Get an the total number of stakers
    /// Note the 0 index will be the contract address and should be ignored
    function getStakerCount() public view returns(uint256) {
        return stakers.length;
    }

    /// @notice Get the bCASH staked, LP staked, tier, and NFTs staked for user
    /// @param _addr the address to check
    function totalViewFor(address _addr) public view returns (uint256, uint256, uint256, uint256[] memory) {
        if (isUser(_addr)){
            return (getStakedBCash(_addr), totalLpForUser(_addr), tierFor(_addr), nftsStakedFor(_addr));
        } 

        uint256[] memory _empty;
        return (0,0,0,_empty);
    }

    // Setters

    function setBC(address bc) public onlyOwner {
        _bc = IERC20(bc);
    }

    function setNFT(address nft) public onlyOwner {
        _nft = IPapilio(nft);
    }

    function setLPFarm1(address farm) public onlyOwner {
        _farm1 = ILPFarm(farm);
    }

    function setLPFarm2(address farm) public onlyOwner {
        _farm2 = ILPFarm(farm);
    }

    function setMaxCap(uint256 _newAmount) public onlyOwner {
        maxCap = _newAmount;
    }

    function setGenerationRate(uint256 _newAmount) public onlyOwner {
        generationRate = _newAmount;
    }

    function setTierLevels(uint256[7] calldata _newAmounts) public onlyOwner {
        tierLevels = _newAmounts;
    }

    function setTierMultipliers(uint256[7] calldata _newAmounts) public onlyOwner {
        tierMultiplier = _newAmounts;
    }

    function setNFTMultiplier(uint256 _newAmount) public onlyOwner {
        nftMultiplier = _newAmount;
    }

    function setMaxNFT(uint256 _newAmount) public onlyOwner {
        maxNFT = _newAmount;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    // Emergency function

    function emergencyWithdrawERC20(address _contract) public onlyOwner {
        IERC20 _token = IERC20(_contract);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    // override
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(allowTransfer, "No can do.");
        super._transfer(from, to, amount);      
    }

}