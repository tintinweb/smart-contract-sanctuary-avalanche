/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-08
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// File: Hackersgameoptimize.sol


pragma solidity ^0.8.4;





contract HackersGameStruct is Ownable{
    IERC721 public hackerNFT0;
    IERC721 public cubeNFT0;
    /*IERC721 public hackerNFT1;
    IERC721 public cubeNFT1;*/
    IERC20 public HACKaddress;

    uint8 constant WALLS = 1;
    uint8 constant FLOOR = 2;
    uint8 constant PC = 3;
    uint8 constant TABLE = 4;
    uint8 constant CONSOLE =5;
    uint8 constant ID = 1;
    uint public stakedHackers;
    uint public stakedCubes;
    mapping(address => uint256) public ownerHackerCount;
    mapping(address => uint256) public ownerCubeCount;
    mapping(address => uint256[]) public walletOfHackerIds;
    mapping(address => uint256[]) public walletOfCubeIds;
    mapping(uint256 => bool) public cubeStakedAlready;
    mapping(uint256 => bool) public legendaryHacker;
    mapping(uint256 => uint256) public hackerLevel;
    mapping(uint256 => bool) public gen0Hacker;
    mapping(uint256 => uint256) public stakedHackerId;
    mapping(uint256 => uint256) public stakedCubeId;
    mapping(uint256 => uint256) public _ransom;
    mapping(uint256 => uint256) public _cubeID;
    mapping(uint256 => mapping(uint256 => uint8)) public _cube_levels;
    mapping(uint8 => mapping(uint8 => uint256)) public _cube_rewards;
    mapping(uint8 => mapping(uint8 => uint256)) public _cube_upgrade_price;
    mapping(address => uint8) public ownerOfHackers;
    mapping(uint256 => uint256) public _currentJob;
    mapping(uint256 => uint256) public _jobRewards;
    mapping(uint256 => uint256) public _jobTime;
   /* mapping(uint256 => uint256) public hackerFeeTimePaid;
    mapping(uint256 => uint256) public cubeFeeTimePaid;
    mapping(uint256 => bool) public cubeRentAble;
    mapping(uint256 => bool) public cubeRented;
    mapping(uint256 => uint256) public cubeRentPrice;*/
    
    constructor () {
        
        /*hackerNFT1 = IERC721(address(0x11280ca3e804D1256c1B2b836d23c92A573c352D));
        cubeNFT1 = IERC721(0x11280ca3e804D1256c1B2b836d23c92A573c352D);*/
        HACKaddress = IERC20(address(this));
        

        _jobRewards[1] = 10**18 * 1;
        _jobRewards[2] = (10**18) * 12/10 * 2;
        _jobRewards[3] = (10**18) * 15/10 * 7;
        _jobRewards[4] = (10**18) * 2 * 14;
        
        _jobTime[1] = 1 days;
        _jobTime[2] = 2 days;
        _jobTime[3] = 7 days;
        _jobTime[4] = 14 days;

        _cube_rewards[WALLS][1] = 100; // x1.0
        _cube_rewards[WALLS][2] = 110; // x1.1
        _cube_rewards[WALLS][3] = 130; // x1.3
        _cube_rewards[WALLS][4] = 150; // x1.5
        _cube_rewards[WALLS][5] = 200; // x2
        
        _cube_rewards[FLOOR][1] = 100; 
        _cube_rewards[FLOOR][2] = 110; 
        _cube_rewards[FLOOR][3] = 130; 
        _cube_rewards[FLOOR][4] = 150; 
        _cube_rewards[FLOOR][5] = 200; 
        
        _cube_rewards[PC][1] = 0.5 ether;
        _cube_rewards[PC][2] = 1.5 ether;
        _cube_rewards[PC][3] = 3 ether; 
        _cube_rewards[PC][4] = 10 ether;
        _cube_rewards[PC][5] = 25 ether;
        
        _cube_rewards[TABLE][1] = 0.3 ether;
        _cube_rewards[TABLE][2] = 1 ether;
        _cube_rewards[TABLE][3] = 3 ether;
        _cube_rewards[TABLE][4] = 8 ether;
        _cube_rewards[TABLE][5] = 20 ether; 
        
        _cube_rewards[CONSOLE][1] = 0.2 ether; // 1%
        _cube_rewards[CONSOLE][2] = 1 ether; // 1%
        _cube_rewards[CONSOLE][3] = 2 ether; // 1%
        _cube_rewards[CONSOLE][4] = 5 ether; // 1%
        _cube_rewards[CONSOLE][5] = 15 ether; // 1%

        _cube_upgrade_price[WALLS][1] = 0; // x1.0
        _cube_upgrade_price[WALLS][2] = 100 ether; // x1.1
        _cube_upgrade_price[WALLS][3] = 500 ether; // x1.3
        _cube_upgrade_price[WALLS][4] = 1000 ether; // x1.5
        _cube_upgrade_price[WALLS][5] = 3000 ether; // x2
        
        _cube_upgrade_price[FLOOR][1] = 0; 
        _cube_upgrade_price[FLOOR][2] = 100 ether; 
        _cube_upgrade_price[FLOOR][3] = 500 ether; 
        _cube_upgrade_price[FLOOR][4] = 1000 ether; 
        _cube_upgrade_price[FLOOR][5] = 3000 ether; 
        
        _cube_upgrade_price[PC][1] = 0;
        _cube_upgrade_price[PC][2] = 150 ether;
        _cube_upgrade_price[PC][3] = 270 ether; 
        _cube_upgrade_price[PC][4] = 700 ether;
        _cube_upgrade_price[PC][5] = 1750 ether;
        
        _cube_upgrade_price[TABLE][1] = 0 ether;
        _cube_upgrade_price[TABLE][2] = 100 ether;
        _cube_upgrade_price[TABLE][3] = 270 ether;
        _cube_upgrade_price[TABLE][4] = 700 ether;
        _cube_upgrade_price[TABLE][5] = 1500 ether; 
        
        _cube_upgrade_price[CONSOLE][1] = 0 ether; // 1%
        _cube_upgrade_price[CONSOLE][2] = 100 ether; // 1%
        _cube_upgrade_price[CONSOLE][3] = 180 ether; // 1%
        _cube_upgrade_price[CONSOLE][4] = 450 ether; // 1%
        _cube_upgrade_price[CONSOLE][5] = 1200 ether; // 1%
        
    }

    function setHacker0Add(address _contractAdd) public onlyOwner{
        hackerNFT0 = IERC721(_contractAdd);
    }
    /*function setHacker1Add(address _contractAdd) public onlyOwner{
        hackerNFT1 = IERC721(_contractAdd);
    }*/
    function setCube0Add(address _contractAdd) public onlyOwner{
        cubeNFT0 = IERC721(_contractAdd);
    }
    /*function setCube1Add(address _contractAdd) public onlyOwner{
        cubeNFT1 = IERC721(_contractAdd);
    }*/
    function walletOfOwnerEverything(address _owner) public view returns(uint256[] memory,uint256[] memory) {
        return (walletOfHackerIds[_owner],walletOfCubeIds[_owner]) ;
    }
}
contract HackersGameOfficial is ERC20, ERC721Holder, HackersGameStruct{

    constructor(address _hacker, address _cube) ERC20("Hack", "HACK") {
        hackerNFT0 = IERC721(_hacker);
        cubeNFT0 = IERC721(_cube);
        hacker.push(Hacker("0",0,0,0,0,0,0,0,0, false,false, address(this)));
        cube.push(Cube(0, 0, false, address(this)));
    }

    struct Hacker{
        string name;
        uint hackingJob;
        uint timeOfHackingJob;
        uint level;
        uint cube;
        uint ID;
        uint rewards;
        uint kidnappedTime;
        uint ransom;
        bool transferable;
        bool kidnapped;
        address owner;
    }
    Hacker[] public hacker;

    struct Cube{
        uint HackerMatch;
        uint ID;
        bool transferable;
        address owner;
    }
    Cube[] public cube;

        function stakeHacker(uint256 tokenId) external {
        hackerNFT0.safeTransferFrom(msg.sender, address(this), tokenId);
        hacker.push(Hacker("",0,0,1,0, tokenId,1.05 ether,0,0, true,false, msg.sender));
        stakedHackers++;
        stakedHackerId[tokenId] = stakedHackers;
        walletOfHackerIds[msg.sender].push(tokenId);
        ownerHackerCount[msg.sender]++;
        if (tokenId == 170 || tokenId == 215 || tokenId == 351 || tokenId == 404 || tokenId == 469 || tokenId == 470 || tokenId == 471 || tokenId == 472 || tokenId == 53 || tokenId == 84){
            legendaryHacker[tokenId] = true;
        } else {
            legendaryHacker[tokenId] = false;
        }
    }

    function unstakeHacker(uint256 tokenId) external {
        require(hacker[tokenId].transferable == true,"Not transferable");
        require(hacker[tokenId].owner == msg.sender, "not owner");
        hackerNFT0.transferFrom(address(this), msg.sender, hacker[tokenId].ID);
        delete hacker[tokenId];
        for (uint i; i < walletOfHackerIds[msg.sender].length; i++){
        if (walletOfHackerIds[msg.sender][i] == tokenId) {
            delete walletOfHackerIds[msg.sender][i];
            uint number = i;
            for (number; number < walletOfHackerIds[msg.sender].length - 1; number++) {
                walletOfHackerIds[msg.sender][number] = walletOfHackerIds[msg.sender][number + 1];
                
            }
        }
    }
    walletOfHackerIds[msg.sender].pop();
    ownerHackerCount[msg.sender]--;
    }
    function matchCube(uint8 tokenId, uint8 _hackerId) external {
        require(hacker[_hackerId].owner == msg.sender, "Not owner"); // checks if owns hacker
        cubeNFT0.safeTransferFrom(msg.sender, address(this), tokenId);
        hacker[_hackerId].cube = tokenId; // adds CUBE to the hacker
        cube.push(Cube( hacker[_hackerId].ID, tokenId, true, msg.sender));
        if (cubeStakedAlready[tokenId] == false){ //checks if cube was staked before to not erase the levels
        _cube_levels[tokenId][WALLS] = 1;
        _cube_levels[tokenId][FLOOR] = 1;
        _cube_levels[tokenId][PC] = 1;
        _cube_levels[tokenId][TABLE] = 1;
        _cube_levels[tokenId][CONSOLE] = 1;
        }
        cubeStakedAlready[tokenId] = true;
        stakedCubes++;
        stakedCubeId[tokenId] = stakedCubes;
        walletOfCubeIds[msg.sender].push(tokenId);
        ownerCubeCount[msg.sender]++;
    }
    function unstakeCube(uint256 tokenId, uint256 hackerId) external {
        require(cube[tokenId].transferable == true,"Not transferable");
        require(cube[tokenId].owner == msg.sender, "Not owner");
        cubeNFT0.transferFrom(address(this), msg.sender, cube[tokenId].ID);
        hacker[hackerId].cube = 0;
        delete cube[tokenId];
        for (uint i; i < walletOfCubeIds[msg.sender].length; i++){
        if (walletOfCubeIds[msg.sender][i] == tokenId) {
            delete walletOfCubeIds[msg.sender][i];
            uint number = i;
            for (number; number < walletOfCubeIds[msg.sender].length - 1; number++) {
                walletOfCubeIds[msg.sender][number] = walletOfCubeIds[msg.sender][number + 1];
                
            }
        }
    }
    walletOfCubeIds[msg.sender].pop();
    ownerCubeCount[msg.sender]--;
    }

    function levelUpHacker(uint256 _hackerId) external payable{
        require(hacker[_hackerId].owner == msg.sender);
        require (hacker[_hackerId].level <= 100,"Max level reached");
        HACKaddress.transferFrom(msg.sender,address(this),hacker[_hackerId].rewards + (hacker[_hackerId].level *10**18/500));
        hacker[_hackerId].level++;
        hacker[_hackerId].rewards = hacker[_hackerId].rewards + 5/100 *10**18;
    }
    function levelUpCube(uint8 cubePart, uint8 _level, uint256 _cubeId) external payable{
        require(_level <= 5,"Invalid level up");
        require(cubePart <= 5 && cubePart >= 1);
        require(_level > _cube_levels[cube[_cubeId].ID][cubePart],"Level is higher");
        require(cube[_cubeId].owner == msg.sender,"Not owner");
        uint256 need_hack = _cube_upgrade_price[cubePart][_level];
        _cube_levels[cube[_cubeId].ID][cubePart] = _level;
        HACKaddress.transferFrom(msg.sender,address(this),need_hack);
    }
    function hackChest(uint _hackerId, uint _cubeId)external payable returns(uint){
        HACKaddress.transferFrom(msg.sender,address(this),500 ether);
        uint randNum = (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100);
        if (randNum <= 50){
            hacker[_hackerId].level++;
            hacker[_hackerId].rewards = hacker[_hackerId].rewards + 0.05 ether;
            return 1;
        } if (randNum >= 50){
            uint cubePart = (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 5);
            _cube_levels[cube[_cubeId].ID][cubePart]++;
            return 2;
        } return 3;
    }
    function calculateTokens(uint _hackerId, uint _cubeId) public view returns(uint){
        uint hacRewards = hacker[_hackerId].rewards;
        uint hacAndCub = ((_cube_rewards[PC][_cube_levels[cube[_cubeId].ID][PC]] + _cube_rewards[CONSOLE][_cube_levels[cube[_cubeId].ID][CONSOLE]] + _cube_rewards[TABLE][_cube_levels[cube[_cubeId].ID][TABLE]]) + hacRewards) * (_cube_rewards[WALLS][_cube_levels[cube[_cubeId].ID][WALLS]] + _cube_rewards[FLOOR][_cube_levels[cube[_cubeId].ID][FLOOR]] - 100);
        if (hacker[_hackerId].cube == 0){
            hacRewards/2;

        } if (legendaryHacker[hacker[_hackerId].ID] == true) {
            hacRewards = hacRewards * 3;

        } if (hacker[_hackerId].ID == cube[_cubeId].ID){
            hacAndCub = hacAndCub*125/100;
        } if (gen0Hacker[_hackerId] == true){
            hacAndCub = hacAndCub*150/100;
        }
        return hacAndCub;
    }

    function hacking(uint tokenId,uint _cubeId, uint _job) external {
        require(hacker[tokenId].kidnapped == false);
        require(_job >= 1 && _job <= 4, "Job does not exist");
        require(hacker[tokenId].hackingJob == 0, "Currently hacking");
        require(hacker[tokenId].owner == msg.sender);
        require(cube[_cubeId].owner == msg.sender);
        require(cube[_cubeId].HackerMatch == hacker[tokenId].ID,"Not matched with this cube");
        hacker[tokenId].hackingJob = _job;
        hacker[tokenId].transferable = false;
        cube[_cubeId].transferable = false;
        hacker[tokenId].timeOfHackingJob = block.timestamp;
        _currentJob[tokenId] = _job;
        hacker[tokenId].ransom = calculateTokens(tokenId,_cubeId) * _jobRewards[_job]/100 ether;

    }
    function finishHacking(uint hackerId, uint _cube, uint _job) external {
        require(hacker[hackerId].owner == msg.sender, "not owner");
        require(hacker[hackerId].hackingJob >= 1, "Not hacking");
        require(_currentJob[hackerId] == _job,"not same job");
        require (block.timestamp >= (hacker[hackerId].timeOfHackingJob + _jobTime[_job]), "wait");
        _mint(msg.sender, calculateTokens(hackerId,_cube) * _jobRewards[_job]/100 ether);
        hacker[hackerId].hackingJob = 0;
        hacker[hackerId].transferable = true;
        cube[_cube].transferable = true;
    }
     uint randNonce = 0;

        function cancelHacking(uint _hackerId, uint _cube,uint _job) external {
        require(hacker[_hackerId].owner == msg.sender, "not owner");
        require(hacker[_hackerId].hackingJob >= 1, "Not hacking");
        require(hacker[_hackerId].hackingJob == _job,"Wrong Job");
        randNonce++;
        uint randNum = (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100);
        if (randNum >= 70){
            _mint(msg.sender, calculateTokens(_hackerId,_cube) * _jobRewards[_job]/100 ether);
            hacker[_hackerId].hackingJob = 0;
            hacker[_hackerId].ransom = 0;
            hacker[_hackerId].timeOfHackingJob = 0;
            hacker[_hackerId].transferable = true;
        }else {
            hacker[_hackerId].transferable = false;
            cube[_cube].transferable = true;
            hacker[_hackerId].kidnappedTime = block.timestamp;
            hacker[_hackerId].kidnapped = true;
        }
    }
       function mintHACK(uint _amount) external{
        require (balanceOf(msg.sender) < 1000 ether);
        _mint(msg.sender, _amount*10**18);
    }
    function payRansom(uint _hackerId) external payable {
        require(hacker[_hackerId].owner == msg.sender,"Not owner");
        require(hacker[_hackerId].kidnappedTime > 0,"not kiddnaped");
        require(hacker[_hackerId].kidnappedTime < hacker[_hackerId].kidnappedTime + 1 minutes,"late");
        HACKaddress.transferFrom(msg.sender,address(this),hacker[_hackerId].ransom);
        hacker[_hackerId].transferable= true;
        hacker[_hackerId].ransom = 0;
        hacker[_hackerId].kidnappedTime = 0;
        hacker[_hackerId].kidnapped = false;
    } 
    function buyKidnappedHacker(uint _hackerId) external payable {
        require(hacker[_hackerId].kidnapped == true,"Not kidnapped");
        require(hacker[_hackerId].kidnappedTime < hacker[_hackerId].kidnappedTime + 1 minutes,"Cannot buy");
        HACKaddress.transferFrom(msg.sender,address(this),hacker[_hackerId].ransom);
        hacker[_hackerId].owner = msg.sender;
        hacker[_hackerId].transferable= true;
        hacker[_hackerId].ransom = 0;
        hacker[_hackerId].kidnappedTime = 0;
        hacker[_hackerId].kidnapped = false;
    }

    // Hacker - 1, Cube - 2
    /*function payFee(uint _cubeOrHacker, uint _Id) external payable { 
        require(_cubeOrHacker <= 2 && _cubeOrHacker > 0,"invalid NFT type");
        if (_cubeOrHacker == 1){
            require(msg.sender == hacker[_Id].owner, "not owner");
            hackerFeeTimePaid[hacker[_Id].ID] = block.timestamp;
            if (hackerFeeTimePaid[hacker[_Id].ID] > block.timestamp - 30 days){
                hackerFeeTimePaid[hacker[_Id].ID] += 30 days;
            }
        }
        if (_cubeOrHacker == 2){
            require(msg.sender == cube[_Id].owner, "not owner");
            cubeFeeTimePaid[cube[_Id].ID] = block.timestamp;
            if (cubeFeeTimePaid[cube[_Id].ID] > block.timestamp - 30 days){
                cubeFeeTimePaid[cube[_Id].ID] += 30 days;
            }
        }
        
    }

    function lendCube(uint _Id, uint _price) external{
        require(cubeFeeTimePaid[cube[_Id].ID] > block.timestamp - 30 days,"unpaid fee");
        require(cube[_Id].transferable == true, "not transferable");
        require(cube[_Id].owner == msg.sender,"not owner");
        cube[_Id].transferable = false;
        cubeRentAble[_Id] = true;
        cubeRentPrice[_Id] = _price;
    }

    function rentCube(uint _cubeId, uint _hackerId) external payable{
        require(cubeRentAble[cube[_cubeId].ID] == true);
        require(hacker[_hackerId].owner == msg.sender);
        HACKaddress.transferFrom(msg.sender,cube[_cubeId].owner, cubeRentPrice[_cubeId]);
        hacker[_hackerId].cube = cube[_cubeId].ID;
        cubeRented[_cubeId] = true;
        cubeRentAble[_cubeId] = false;
    }

    function cancelCubeLending() public {

    }*/
}