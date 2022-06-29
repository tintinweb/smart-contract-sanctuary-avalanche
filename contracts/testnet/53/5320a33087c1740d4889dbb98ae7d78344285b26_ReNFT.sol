/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

interface IResolver {
    /// ENUMS ///

    enum PaymentToken {
        SENTINEL,
        WETH,
        DAI,
        USDC,
        USDT,
        TUSD,
        RENT
    }

    /// CONSTANT FUNCTIONS ///

    function getPaymentToken(PaymentToken paymentToken)
        external
        view
        returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    function setPaymentToken(uint8 paymentToken, address value) external;
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * Resolver: IResolver.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface INFTContract {
    /// ERC1155 ///

    /// @notice Get the balance of an account's tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the token
    /// @return        The owner's balance of the token type requested
    function balanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfers `value` amount of an `id` from the `from` address to the `to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// MUST revert if `to` is the zero address.
    /// MUST revert if balance of holder for token `id` is lower than the `value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /// @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
    /// MUST revert if `to` is the zero address.
    /// MUST revert if length of `ids` is not the same as length of `values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
    /// MUST revert on any other error.
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (ids[0]/values[0] before ids[1]/values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param from    Source address
    /// @param to      Target address
    /// @param ids     IDs of each token type (order and length must match values array)
    /// @param values  Transfer amounts per token type (order and length must match ids array)
    /// @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /// ERC165 ///

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    // -------------------------------------------------------------------------------
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * INFTContract: INFTContract.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

interface IReNFT is IERC1155Receiver {
    /// STRUCTS ///

    struct Nfts {
        INFTContract nft;
        uint256[] tokenIds;
        uint256[] lendingIds;
    }

    /// @dev Since we need to persist lendings forever (check the
    /// LendingRenting struct's doc), we need a flag to let us know
    /// if lending is active or not. inactive attribute will serve this
    /// purpose. By default, when lending is created, it will be false.
    /// We will set this attribute to true, when the owner of the NFT
    /// stops lending.
    struct Lending {
        address payable[] allowedRenters; /// whitelisted addresses
        RevShare revShares;
        uint256 upfrontRentFee; /// Useful in detrring bots when whitelists not set
        address payable lenderAddress;
        uint8 maxRentDuration;
        IResolver.PaymentToken paymentToken;
        bool inactive;
    }

    /// @dev Graph protocol was not able to generate types for 2D arrays.
    /// A solution is to wrap the inner most array in a struct. And have
    /// AllowedRenters[] as an input to a function.
    struct AllowedRenters {
        address payable[] allowedRenters;
    }

    /// @dev This struct is part of the Lending struct. Therefore,
    /// payment token of the lending is what the rewards are split
    /// in.
    struct RevShare {
        address payable[] beneficiaries;
        uint8[] portions;
    }

    struct Renting {
        address payable renterAddress;
        uint32 rentedAt;
        uint8 rentDuration;
    }

    struct LendingRenting {
        Lending lending;
        Renting renting;
    }

    /// EVENTS ///

    event Lend(
        address indexed nftAddress,
        uint256 upfrontRentFee,
        address payable[] allowedRenters,
        RevShare revShares,
        uint8 maxRentDuration,
        IResolver.PaymentToken paymentToken,
        address indexed lenderAddress,
        uint256 indexed tokenId,
        uint256 lendingId
    );

    event Rent(
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint8 rentDuration
    );

    event StopLend(uint256 indexed lendingId);

    event StopRent(uint256 indexed lendingId);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sends your NFT(s) to ReNFT contract, which acts as an escrow
    /// between the lender and the renter. Called by lender.
    /// @param nfts NFT(s) to be lent.
    /// @param allowedRenters Only these addresses can rent.
    /// @param revShares Specifies the beneficiaries of the revenue share,
    /// as well as, their respective portions. These portions sum up to less
    /// than 100. This is because the renter is entitiled to 100 - sum(portions).
    /// Reason the renter address is not here, is because it is not possible to
    /// know who will rent this given lending at the time of lending creation.
    /// @param maxRentDurations Max allowed rent duration per NFT.
    /// @param paymentToken    Index of the payment token with which to pay the
    /// rewards.
    function lend(
        Nfts calldata nfts,
        uint256[] calldata upfrontRentFee,
        AllowedRenters[] calldata allowedRenters,
        RevShare[] calldata revShares,
        uint8[] calldata maxRentDurations,
        IResolver.PaymentToken[] calldata paymentToken
    ) external;

    /// @notice Renter sends the rent payment and receives tenancy rights.
    /// @param nfts NFT(s) to be rented.
    /// @param rentDurations Number of days that the renter wishes to rent the NFT for.
    /// It is possible to return the NFT prior to this. In which case, the renter
    /// receives the unused balance.
    function rent(Nfts calldata nfts, uint8[] calldata rentDurations)
        external
        payable;

    /// @notice Stop lending releases the NFT(s) from escrow and sends it back
    /// to the lender. Called by lender.
    /// @param nfts NFT(s) to stop lending.
    function stopLend(Nfts calldata nfts) external;

    /// @notice Renters call this to conclude renting the NFT before the
    /// deadline.
    /// @param nfts NFT(s) to be returned.
    function stopRent(Nfts calldata nfts) external;

    /// @notice This function gets called by the integrating project only.
    /// It will split the rewards as per the lending.
    /// @param nfts NFT(s) to identify the lendings.
    /// @param renter Renter(s) to identify the renters, since they
    /// always get a revenue share.
    /// @param amountToPay Amount to pay to the rev share parties.
    function pay(
        Nfts calldata nfts,
        address payable[] calldata renter,
        uint256[] calldata amountToPay
    ) external;
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * ReNFT: IReNFT.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

library NFTCommon {

    /// @notice Transfers the NFT tokenID from to.
    /// @dev safeTransferFrom_ name to avoid collision with the interface signature definitions. The reason it is implemented the way it is,
    /// is because some NFT contracts implement both the 721 and 1155 standard at the same time. Sometimes, 721 or 1155 function does not work.
    /// So instead of relying on the user's input, or asking the contract what interface it implements, it is best to just make a good assumption
    /// about what NFT type it is (here we guess it is 721 first), and if that fails, we use the 1155 function to tranfer the NFT.
    /// @param nft     NFT address
    /// @param from    Source address
    /// @param to      Target address
    /// @param tokenID ID of the token type
    /// @return        true = transfer successful, false = transfer not successful
    function safeTransferFrom_(
        INFTContract nft,
        address from,
        address to,
        uint256[] memory tokenID
    ) internal returns (bool) {

        uint256[] memory amount = new uint256[](tokenID.length);
        for (uint256 i = 0; i < tokenID.length; i++) {
            amount[i] = 1;
        }

        // ERC-1155
        try nft.safeBatchTransferFrom(from, to, tokenID, amount, new bytes(0)) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * NFTCommon: NFTCommon.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

/// @notice Emitted when the item cannot be rented.
/// 0 errorCode means that renter is attempting to rent an inactive lending.
/// 1 errorCode means that renter is the creator of the lending.
/// 2 errorCode means that rentDuration is less than one period.
error NotRentable(uint8 errorCode);

/// @notice Emitted when the lending should be non-initiated, but is in fact initiated.
error LendingNotEmpty();

/// @notice Empitted when the lending should be initiated, but is in fact non-initiated.
error LendingEmpty();

/// @notice Emitted when the renter is not allowed to rent.
error NotWhitelistedToRent();

/// @notice Emitted when the address stopping the lending is not the lender.
error StopperNotLender(address lender, address msgSender);

/// @notice Emitted when rent duration exceeds max rent duration.
/// @param rentDuration Rent duration.
/// @param maxRentDuration Max allowed rent duration.
error RentDurationExceedsMaxRentDuration(
    uint8 rentDuration,
    uint8 maxRentDuration
);

/// @notice Emitted when lender tries to stop an inactive lending
error LendingNotActive();

library LendingChecks {
    function checkIsEmpty(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress != address(0)) {
            revert LendingNotEmpty();
        }
    }

    function checkIsNotEmpty(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress == address(0)) {
            revert LendingEmpty();
        }
    }

    function checkIsRentable(
        IReNFT.Lending storage lending,
        uint8[] calldata rentDurations,
        uint256 i,
        address msgSender
    ) internal view {
        if (lending.inactive == true) {
            revert NotRentable(0);
        }
        if (msgSender == lending.lenderAddress) {
            revert NotRentable(1);
        }
        /// Minimal rent duration is one period
        if (rentDurations[i] < 1) {
            revert NotRentable(2);
        }
        /// Note that rentDuration == lending.maxRentDuration is allowed
        if (rentDurations[i] > lending.maxRentDuration) {
            revert RentDurationExceedsMaxRentDuration(
                rentDurations[i],
                lending.maxRentDuration
            );
        }
        /// If allowed renters is an empty array, anyone can rent
        if (lending.allowedRenters.length > 0) {
            /// Means only whitelisted addresses can rent
            bool canRent = false;
            for (uint256 j = 0; j < lending.allowedRenters.length; j++) {
                if (msg.sender == lending.allowedRenters[j]) {
                    canRent = true;
                    break;
                }
            }
            if (!canRent) {
                revert NotWhitelistedToRent();
            }
        }
    }

    function checkIsStoppable(IReNFT.Lending storage lending) internal view {
        if (lending.lenderAddress != msg.sender) {
            revert StopperNotLender(lending.lenderAddress, msg.sender);
        }
        if (lending.inactive == true) {
            revert LendingNotActive();
        }
    }
}

/// @notice Emitted when the renting should be non-initiated, but is in fact initiated.
error RentingNotEmpty();

/// @notice Emitted when the renting should be initiated, but is in fact non-initiated.
error RentingEmpty();

library RentingChecks {
    function checkIsEmpty(IReNFT.Renting storage renting) internal view {
        if (renting.renterAddress != address(0)) {
            revert RentingNotEmpty();
        }
    }

    function checkIsNotEmpty(IReNFT.Renting storage renting) internal view {
        if (renting.renterAddress == address(0)) {
            revert RentingEmpty();
        }
    }

}

//              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
//              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
//         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
//         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
//         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
//    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
//    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
//    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
//         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
//         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
//         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
//              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
//              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
//                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@

/// @notice Emitted when fallback is triggered
error FallbackNotAllowed();

/// @notice Emitted when NFT transfer fails
error NftTransferFailed();

/// @notice Emitted when the caller is not an admin.
error NotAdmin(address caller);

/// @notice Emitted when the paused function is called.
error Paused();

/// @notice Emitted when length of receivers and their fee portions does not match.
error InvalidProtocolFeeReceivers();

/// @notice Emitted when the portions do not sum to 100.
error InvalidPortionsSum();

/// @notice Emitted when the item cannot lent or an existing lending item cannot be edited.
/// 0 errorCode means that maxRentDuration is zero
/// 1 errorCode means that paymentTokenAddress is zero
/// 2 errorCode is emitted when upfront fee is not set when renter addresses are empty. When there is no whitelisted addresses, anyone would be able to rent for free and not play the game.
/// 3 errorCode is emitted when the beneficiaries (for reward splits) array length is less than 1. You should always have at least 1: owner of the nft.
/// 4 errorCode is emitted when beneficiaries length is not the same as portions length.
/// 5 errorCode is emitted when sum of portions is 100 or more. Sum of portions must be less than 100. Renter is defined to receive 100 - sum (revShares.portions).
error NotLendable(uint8 errorCode);

/// @notice Emitted when there is an error in reward share split function
/// 0 errorCode means that the address that is attempting to pay is not part of `rewardPayers`.
error NotPayable(uint8 errorCode);

/// @notice Emitted when the renting is stopped by non reNFT bot.
error ReturningNotAllowed();

/// @notice ReNFT
/// @author reNFT
contract ReNFT is IReNFT, ERC721Holder, ERC1155Receiver, ERC1155Holder {
    using SafeERC20 for ERC20;
    using NFTCommon for INFTContract;
    using LendingChecks for Lending;
    using RentingChecks for Renting;

    IResolver private resolver;
    address private admin;
    address private deployer;
    // Protocol fee receivers and their respective share of the fee.
    // Sum of portions = 100. Thus, if a feeReceiver has 20 portions,
    // They are entitled to 20% of all of the protocol fees.
    address payable[] private feeReceivers;
    uint8[] private feePortions;

    // These are reNFT ran bots that stop the rentals for renters
    // automatically. This means the renters do not have to worry
    // about stopping the rental of the NFT on time.
    address[] private rentStoppers;

    // These are the addresses that are allowed to pay the rev share
    // rewards.
    address[] private rewardPayers;

    uint256 private lendingId = 1;

    bool public paused = false;
    // In basis points. So 1_000 means 1%.
    // Can't be greater or equal than 10_000
    uint256 public rentFee = 0;

    mapping(bytes32 => LendingRenting) public lendingRentings;

    modifier onlyAdmin() {
        if (msg.sender != admin && msg.sender != deployer) {
            revert NotAdmin(msg.sender);
        }
        _;
    }

    modifier onlyRentStoppers() {
        bool canStop = false;
        for (uint256 i = 0; i < rentStoppers.length; i++) {
            if (msg.sender == rentStoppers[i]) {
                canStop = true;
                break;
            }
        }
        if (!canStop) {
            revert ReturningNotAllowed();
        }
        _;
    }

    modifier notPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    constructor(address newResolver, address newAdmin) {
        /// ! Note that after creating the contract, you need to:
        /// - set rent fee (`setRentFee`)
        /// - set protocol fee receivers (`setProtocolFeeReceivers`). (beneficiaries and portions)
        /// - set rent stoppers (`setRentStoppers`). Bots that will stop the rentals
        /// - set reward payers (`setRewardPayers`). Rev share split payers
        resolver = IResolver(newResolver);
        admin = newAdmin;
        deployer = msg.sender;
    }

    /// EFFECTS - MAIN LOGIC - USER ENTRYPOINTS ///

    /// @inheritdoc IReNFT
    function lend(
        Nfts calldata nfts,
        uint256[] calldata upfrontRentFee,
        AllowedRenters[] calldata allowedRenters,
        RevShare[] calldata revShares,
        uint8[] calldata maxRentDurations,
        IResolver.PaymentToken[] calldata paymentTokens
    ) external override notPaused {
        for (uint256 i = 0; i < nfts.tokenIds.length; i++) {
            /// Note, you must call with empty allowedRenters arrays, if you wish for everyone to
            /// be able to rent. If you don't, you will get an index out of bounds.
            checkIsLendable(
                upfrontRentFee[i],
                allowedRenters[i],
                revShares[i],
                maxRentDurations[i],
                paymentTokens[i]
            );

            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        nfts.nft,
                        nfts.tokenIds[i],
                        lendingId
                    )
                )
            ];

            item.lending.checkIsEmpty();
            item.renting.checkIsEmpty();

            item.lending = Lending({
                lenderAddress: payable(msg.sender),
                upfrontRentFee: upfrontRentFee[i],
                allowedRenters: allowedRenters[i].allowedRenters,
                revShares: revShares[i],
                maxRentDuration: maxRentDurations[i],
                inactive: false,
                paymentToken: paymentTokens[i]
            });

            emit Lend({
                nftAddress: address(nfts.nft),
                tokenId: nfts.tokenIds[i],
                upfrontRentFee: upfrontRentFee[i],
                lendingId: lendingId,
                lenderAddress: msg.sender,
                allowedRenters: allowedRenters[i].allowedRenters,
                revShares: revShares[i],
                maxRentDuration: maxRentDurations[i],
                paymentToken: paymentTokens[i]
            });

            lendingId++;
        }

        bool success = nfts.nft.safeTransferFrom_(
            msg.sender,
            address(this),
            nfts.tokenIds
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// @inheritdoc IReNFT
    function rent(Nfts calldata nfts, uint8[] calldata rentDurations) external payable override notPaused {
        for (uint256 i = 0; i < nfts.tokenIds.length; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        nfts.nft,
                        nfts.tokenIds[i],
                        nfts.lendingIds[i]
                    )
                )
            ];

            /// Pay the upfront fee directly into the lender's wallet.
            if (item.lending.upfrontRentFee != 0) {
                /// When the lending is created, upfrontRentFee is an unscaled value
                /// To scale it, we must determine number of decimals in a given erc20
                /// and scale upfrontRentFee accordingly.
                ERC20 pmtToken = ERC20(resolver.getPaymentToken(item.lending.paymentToken));
                uint256 decimals = pmtToken.decimals();
                uint256 upfrontFee = item.lending.upfrontRentFee * (10 ** decimals);

                pmtToken.safeTransferFrom(
                    msg.sender,
                    item.lending.lenderAddress,
                    upfrontFee
                );
            }

            item.lending.checkIsNotEmpty();
            item.renting.checkIsEmpty();
            item.lending.checkIsRentable(rentDurations, i, msg.sender);

            item.renting.renterAddress = payable(msg.sender);
            item.renting.rentDuration = rentDurations[i];
            item.renting.rentedAt = uint32(block.timestamp);

            emit Rent({
                lendingId: nfts.lendingIds[i],
                renterAddress: msg.sender,
                rentDuration: rentDurations[i]
            });
        }
    }

    /// @inheritdoc IReNFT
    function stopRent(Nfts calldata nfts) external override notPaused onlyRentStoppers {
        for (uint256 i = 0; i < nfts.tokenIds.length; i++) {
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        nfts.nft,
                        nfts.tokenIds[i],
                        nfts.lendingIds[i]
                    )
                )
            ];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsNotEmpty();

            delete item.renting;

            emit StopRent({lendingId: nfts.lendingIds[i]});
        }
    }

    /// @inheritdoc IReNFT
    function stopLend(Nfts calldata nfts) external override notPaused {
        for (uint256 i = 0; i < nfts.tokenIds.length; i++) {
            bytes32 identifier = keccak256(
                abi.encodePacked(
                    nfts.nft,
                    nfts.tokenIds[i],
                    nfts.lendingIds[i]
                )
            );
            LendingRenting storage item = lendingRentings[identifier];

            item.lending.checkIsNotEmpty();
            item.renting.checkIsEmpty();
            item.lending.checkIsStoppable();

            /// We can't delete the lendings because we need to keep track of rev share
            /// splits, in case some of the rentings haven't split the rewards
            item.lending.inactive = true;

            emit StopLend({lendingId: nfts.lendingIds[i]});
        }

        bool success = nfts.nft.safeTransferFrom_(
            address(this),
            msg.sender,
            nfts.tokenIds
        );

        if (!success) {
            revert NftTransferFailed();
        }
    }

    /// FINANCIAL ///

    /// @inheritdoc IReNFT
    function pay(
        Nfts calldata nfts,
        address payable[] calldata renter,
        uint256[] calldata amountToPay
    ) external override notPaused {
        /// If you cannot pay with this function, call it with less arguments
        /// i.e. break up the payments

        /// only payable by one of the allowed addresses
        bool canPay = false;
        for (uint256 i = 0; i < rewardPayers.length; i++) {
            /// relayer might be executing the actual transaction
            if (tx.origin == rewardPayers[i]) {
                canPay = true;
                break;
            }
        }
        if (!canPay) {
            revert NotPayable(0);
        }

        /// amountToPay - takeFee now available to be distributed between
        /// the rev share receipents in the correct amounts

        /// Possible to pay for multiple rentings at the same time
        uint8 outerLen = uint8(nfts.lendingIds.length);
        for (uint8 i = 0; i < outerLen; i++) {
            /// get the lendingRenting item (you need this for rev share details)
            LendingRenting storage item = lendingRentings[
                keccak256(
                    abi.encodePacked(
                        nfts.nft,
                        nfts.tokenIds[i],
                        nfts.lendingIds[i]
                    )
                )
            ];

            /// - takeFee on the amountToPay. distribute it between the protocol fee receivers
            uint256 takenFee = takeFee(amountToPay[i], item.lending.paymentToken);
            uint256 rewardAmount = amountToPay[i] - takenFee;
            uint8 innerLen = uint8(item.lending.revShares.beneficiaries.length);
            uint256 rewardPart = 0;
            uint8 sum = 0;
            /// All but renter. We have checked during lending that sum of revShares portions
            /// is less than 100
            for (uint8 j = 0; j < innerLen; j++) {
                sum += item.lending.revShares.portions[j];
                rewardPart = (rewardAmount * item.lending.revShares.portions[j]) / 100;
                if (rewardPart != 0) {
                    ERC20(resolver.getPaymentToken(item.lending.paymentToken)).safeTransferFrom(
                        tx.origin,
                        item.lending.revShares.beneficiaries[j],
                        rewardPart
                    );
                }
            }
            uint256 renterPortion = 100 - uint256(sum);
            rewardPart = (rewardAmount * renterPortion) / 100;
            if (rewardPart != 0) {
                ERC20(resolver.getPaymentToken(item.lending.paymentToken)).safeTransferFrom(
                    tx.origin,
                    renter[i],
                    rewardPart
                );    
            }
        }
    }

    /// @notice Takes protocol fee from the realised rent amounts.
    /// @param revShareAmount Once rev share payment is made, we take the protocol fee
    /// on this sum.
    /// @param paymentToken Index of the token from the Resolver. The `rentAmount`
    /// will be sent denominated in this token.
    function takeFee(uint256 revShareAmount, IResolver.PaymentToken paymentToken) private returns (uint256 fee) {
        fee = (revShareAmount * rentFee) / 10000;
        if (fee == 0) {
            return 0;
        }
        uint8 len = uint8(feeReceivers.length);
        uint256 feePart = 0;
        for (uint8 i = 0; i < len; i++) {
            feePart = (fee * feePortions[i]) / 100;
            if (feePart != 0) {
                ERC20(resolver.getPaymentToken(paymentToken)).safeTransferFrom(
                    tx.origin,
                    feeReceivers[i],
                    feePart
                );
            }
        }
        /// fee is implicitly returned
    }

    /// CHECKS ///

    function checkIsLendable(
        uint256 upfrontRentFee,
        AllowedRenters calldata allowedRenters,
        RevShare calldata revShares,
        uint8 maxRentDuration,
        IResolver.PaymentToken paymentToken
    ) private view {
        /// Enforce at least one period length max rent duration
        if (maxRentDuration < 1) {
            revert NotLendable(0);
        }

        if (allowedRenters.allowedRenters.length == 0) {
            /// Everyone can rent.
            /// Upfront fee is mandatory in such a case.
            if (upfrontRentFee == 0) {
                revert NotLendable(2);
            }
        }
        /// else, if the upfrontRentFee allowed renters length is not zero
        /// means only certain few addresses can rent
        /// in that case the upfrontRentFee can or cannot be zero
        /// most of the cases it will be zero, since the lender
        /// will trust the allowedRenters
        /// The reason for mandatory upfrontRentFee when allowedRenters
        /// length is zero is because someone can write a bot to immediately
        /// rent such lendings (free obviously, becaues upfrontRentFee is zero)
        /// and then not use them to play the game, which would causes issues.
        /// Now you obviously, can have small upfrontRentFees when
        /// allowedRenters length is zero, but it is still a better 
        /// solution than no fee at all
        /// Therefore, is allowedRenters length is not zero, we do not need
        /// to make any additional checks.

        address paymentTokenAddr = resolver.getPaymentToken(paymentToken);
        /// Only if upfrontRentFee is zero can you leave the payment token
        /// as sentinel. If this weren't the case, you'd be wasting 20k
        /// gas to set the zero payment token to something that is non-zero
        /// and would be simply wasting gas
        /// TODO: update the SDK whoopi.js example to use SENTINEL when
        /// upfrontRentFee is zero
        if (upfrontRentFee != 0) {
            if (paymentTokenAddr == address(0)) {
                revert NotLendable(1);
            }
        }

        /// Rev Share Checks

        /// RevShares beneficiaries should be at least one: the owner of the nft
        /// Renter is also in there, but renter's share is defined as:
        /// 100 - sum (revShares.portions). Plus, we can't know who the renter
        /// is at the time of the actual rent creation. Plus, you can have same
        /// lending, but multiple renters; Thus, we can't define the renter
        /// at the time of lending creation.
        if (revShares.beneficiaries.length < 1) {
            revert NotLendable(3);
        }

        if (revShares.beneficiaries.length != revShares.portions.length) {
            revert NotLendable(4);
        }

        /// Sum of portions must be less than 100.
        /// This is because the renter gets 100 - sum (revShare.portions).
        uint8 sum = computeSum(revShares.portions);
        if (sum >= 100) {
            revert NotLendable(5);
        }
    }

    function computeSum(uint8[] calldata portions) private pure returns (uint8 sum) {
        uint8 len = uint8(portions.length);
        sum = 0;
        for (uint8 i = 0; i < len; i ++) {
            sum += portions[i];
        }
    }

    function checkPortionsSum(uint8[] calldata portions) private pure {
        uint8 sum = computeSum(portions);
        if (sum != 100) {
            revert InvalidPortionsSum();
        }
    }

    /// ADMIN ///

    function revokeOwnership() external onlyAdmin {
        admin = address(0);
    }

    function setRentFee(uint256 newRentFee) external onlyAdmin {
        rentFee = newRentFee;
    }

    function setProtocolFeeReceivers(
        address payable[] calldata newFeeReceivers,
        uint8[] calldata newFeePortions
    ) external onlyAdmin {
        /// ! This function needs to be immediately called after deploying the contract
        checkPortionsSum(newFeePortions);
        if (newFeeReceivers.length != newFeePortions.length) {
            revert InvalidProtocolFeeReceivers();
        }
        feeReceivers = newFeeReceivers;
        feePortions = newFeePortions;
    }

    function setRentStoppers(
        address[] calldata newRentStoppers
    ) external onlyAdmin {
        /// ! This function needs to be immediately called after deploying the contract
        rentStoppers = newRentStoppers;
    }

    function setRewardPayers(
        address[] calldata newRewardPayers
    ) external onlyAdmin {
        /// ! This function needs to be immediately called after deploying the contract
        rewardPayers = newRewardPayers;
    }

    function flipPaused() external onlyAdmin {
        paused = !paused;
    }
}

/*
 *
 *              @@@@@@@@@@@@@@@@        ,@@@@@@@@@@@@@@@@
 *              @@@,,,,,,,,,,@@@        ,@@&,,,,,,,,,,@@@
 *         @@@@@@@@,,,,,,,,,,@@@@@@@@&  ,@@&,,,,,,,,,,@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@
 *         @@@**********@@@@@@@@@@@@@&  ,@@@@@@@@**********@@@@@@@@
 *         @@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@@@@@@&       [email protected]@@**********@@@@@@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@
 *    @@@**********@@@@@@@@@@@@@&            [email protected]@@@@@@@**********@@@@@@@@
 *    @@@@@@@@**********@@@@@@@@&            [email protected]@@**********@@@@@@@@@@@@@
 *    @@@@@@@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&            [email protected]@@//////////@@@@@@@@@@@@@
 *         @@@//////////@@@@@@@@&       ,@@@@@@@@//////////@@@@@@@@@@@@@
 *         @@@%%%%%/////(((((@@@&       ,@@@(((((/////%%%%%@@@@@@@@
 *         @@@@@@@@//////////@@@@@@@@&  ,@@@//////////@@@@@@@@@@@@@
 *              @@@%%%%%%%%%%@@@@@@@@&  ,@@@%%%%%%%%%%@@@@@@@@@@@@@
 *              @@@@@@@@@@@@@@@@@@@@@&  ,@@@@@@@@@@@@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@
 *                   @@@@@@@@@@@@@@@@&        @@@@@@@@@@@@@@@@ *
 *
 * ReNFT: ReNFT.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 reNFT Labs Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */