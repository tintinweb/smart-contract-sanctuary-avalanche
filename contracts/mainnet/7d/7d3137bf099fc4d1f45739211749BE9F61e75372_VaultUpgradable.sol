// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Minimal interface for Vault compatible strategies.
/// @dev Designed for out of the box compatibility with Fuse cTokens.
/// @dev Like cTokens, strategies must be transferrable ERC20s.
abstract contract Strategy {
	/// @notice Returns whether the strategy accepts ETH or an ERC20.
	/// @return True if the strategy accepts ETH, false otherwise.
	/// @dev Only present in Fuse cTokens, not Compound cTokens.
	function isCEther() external view virtual returns (bool);

	/// @notice Withdraws a specific amount of underlying tokens from the strategy.
	/// @param amount The amount of underlying tokens to withdraw.
	/// @return An error code, or 0 if the withdrawal was successful.
	function redeemUnderlying(uint256 amount) external virtual returns (uint256);

	/// @notice Returns a user's strategy balance in underlying tokens.
	/// @param user The user to get the underlying balance of.
	/// @return The user's strategy balance in underlying tokens.
	/// @dev May mutate the state of the strategy by accruing interest.
	function balanceOfUnderlying(address user) external virtual returns (uint256);

	/// @notice Returns max deposits a strategy can take.
	/// @return MaxTvl
	function getMaxTvl() external virtual returns (uint256);

	/// @notice Withdraws any ERC20 tokens back to recipient.
	function emergencyWithdraw(address recipient, IERC20[] memory tokens) external virtual;
}

/// @notice Minimal interface for Vault strategies that accept ERC20s.
/// @dev Designed for out of the box compatibility with Fuse cERC20s.
abstract contract ERC20Strategy is Strategy {
	/// @notice Returns the underlying ERC20 token the strategy accepts.
	/// @return The underlying ERC20 token the strategy accepts.
	function underlying() external view virtual returns (IERC20);

	/// @notice Deposit a specific amount of underlying tokens into the strategy.
	/// @param amount The amount of underlying tokens to deposit.
	/// @return An error code, or 0 if the deposit was successful.
	function mint(uint256 amount) external virtual returns (uint256);
}

/// @notice Minimal interface for Vault strategies that accept ETH.
/// @dev Designed for out of the box compatibility with Fuse cEther.
abstract contract ETHStrategy is Strategy {
	/// @notice Deposit a specific amount of ETH into the strategy.
	/// @dev The amount of ETH is specified via msg.value. Reverts on error.
	function mint() external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function withdraw(uint256) external;

	function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// from Solmate by Rari-Capital https://github.com/Rari-Capital/solmate

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
	/*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

	uint256 internal constant YAD = 1e8;
	uint256 internal constant WAD = 1e18;
	uint256 internal constant RAY = 1e27;
	uint256 internal constant RAD = 1e45;

	/*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

	function fmul(
		uint256 x,
		uint256 y,
		uint256 baseUnit
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * y in z for now.
			z := mul(x, y)

			// Equivalent to require(x == 0 || (x * y) / x == y)
			if iszero(or(iszero(x), eq(div(z, x), y))) {
				revert(0, 0)
			}

			// If baseUnit is zero this will return zero instead of reverting.
			z := div(z, baseUnit)
		}
	}

	function fdiv(
		uint256 x,
		uint256 y,
		uint256 baseUnit
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * baseUnit in z for now.
			z := mul(x, baseUnit)

			// Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
			if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
				revert(0, 0)
			}

			// We ensure y is not zero above, so there is never division by zero here.
			z := div(z, y)
		}
	}

	function fpow(
		uint256 x,
		uint256 n,
		uint256 baseUnit
	) internal pure returns (uint256 z) {
		assembly {
			switch x
			case 0 {
				switch n
				case 0 {
					// 0 ** 0 = 1
					z := baseUnit
				}
				default {
					// 0 ** n = 0
					z := 0
				}
			}
			default {
				switch mod(n, 2)
				case 0 {
					// If n is even, store baseUnit in z for now.
					z := baseUnit
				}
				default {
					// If n is odd, store x in z for now.
					z := x
				}

				// Shifting right by 1 is like dividing by 2.
				let half := shr(1, baseUnit)

				for {
					// Shift n right by 1 before looping to halve it.
					n := shr(1, n)
				} n {
					// Shift n right by 1 each iteration to halve it.
					n := shr(1, n)
				} {
					// Revert immediately if x ** 2 would overflow.
					// Equivalent to iszero(eq(div(xx, x), x)) here.
					if shr(128, x) {
						revert(0, 0)
					}

					// Store x squared.
					let xx := mul(x, x)

					// Round to the nearest number.
					let xxRound := add(xx, half)

					// Revert if xx + half overflowed.
					if lt(xxRound, xx) {
						revert(0, 0)
					}

					// Set x to scaled xxRound.
					x := div(xxRound, baseUnit)

					// If n is even:
					if mod(n, 2) {
						// Compute z * x.
						let zx := mul(z, x)

						// If z * x overflowed:
						if iszero(eq(div(zx, x), z)) {
							// Revert if x is non-zero.
							if iszero(iszero(x)) {
								revert(0, 0)
							}
						}

						// Round to the nearest number.
						let zxRound := add(zx, half)

						// Revert if zx + half overflowed.
						if lt(zxRound, zx) {
							revert(0, 0)
						}

						// Return properly scaled zxRound.
						z := div(zxRound, baseUnit)
					}
				}
			}
		}
	}

	/*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly {
			// Start off with z at 1.
			z := 1

			// Used below to help find a nearby power of 2.
			let y := x

			// Find the lowest power of 2 that is at least sqrt(x).
			if iszero(lt(y, 0x100000000000000000000000000000000)) {
				y := shr(128, y) // Like dividing by 2 ** 128.
				z := shl(64, z)
			}
			if iszero(lt(y, 0x10000000000000000)) {
				y := shr(64, y) // Like dividing by 2 ** 64.
				z := shl(32, z)
			}
			if iszero(lt(y, 0x100000000)) {
				y := shr(32, y) // Like dividing by 2 ** 32.
				z := shl(16, z)
			}
			if iszero(lt(y, 0x10000)) {
				y := shr(16, y) // Like dividing by 2 ** 16.
				z := shl(8, z)
			}
			if iszero(lt(y, 0x100)) {
				y := shr(8, y) // Like dividing by 2 ** 8.
				z := shl(4, z)
			}
			if iszero(lt(y, 0x10)) {
				y := shr(4, y) // Like dividing by 2 ** 4.
				z := shl(2, z)
			}
			if iszero(lt(y, 0x8)) {
				// Equivalent to 2 ** z.
				z := shl(1, z)
			}

			// Shifting right by 1 is like dividing by 2.
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))

			// Compute a rounded down version of z.
			let zRoundDown := div(x, z)

			// If zRoundDown is smaller, use it.
			if lt(zRoundDown, z) {
				z := zRoundDown
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// from Solmate by Rari-Capital https://github.com/Rari-Capital/solmate

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
	function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
		require(x <= type(uint248).max);

		y = uint248(x);
	}

	function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
		require(x <= type(uint128).max);

		y = uint128(x);
	}

	function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
		require(x <= type(uint96).max);

		y = uint96(x);
	}

	function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
		require(x <= type(uint64).max);

		y = uint64(x);
	}

	function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
		require(x <= type(uint32).max);

		y = uint32(x);
	}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import { SafeCastLib } from "../libraries/SafeCastLib.sol";
import { FixedPointMathLib } from "../libraries/FixedPointMathLib.sol";

import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/uniswap/IWETH.sol";

// import "hardhat/console.sol";

import { Strategy, ERC20Strategy, ETHStrategy } from "../interfaces/Strategy.sol";

/// @title Rari Vault (rvToken)
/// @author Transmissions11 and JetJadeja
/// @notice Flexible, minimalist, and gas-optimized yield aggregator for
/// earning interest on any ERC20 token.
contract VaultUpgradable is
	Initializable,
	ERC20Upgradeable,
	OwnableUpgradeable,
	ReentrancyGuardUpgradeable
{
	using SafeCastLib for uint256;
	using SafeERC20 for IERC20;
	using FixedPointMathLib for uint256;

	/// security: marks implementation contract as initialized
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	/// @notice The underlying token the Vault accepts.
	IERC20 public UNDERLYING;

	/// @notice The base unit of the underlying token and hence rvToken.
	/// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
	uint256 public BASE_UNIT;

	uint256 private _decimals;

	/// @notice Emitted when the Vault is initialized.
	/// @param user The authorized user who triggered the initialization.
	event Initialized(address indexed user);

	/// @notice Creates a new Vault that accepts a specific underlying token.
	/// @param _UNDERLYING The ERC20 compliant token the Vault should accept.
	function initialize(
		IERC20 _UNDERLYING,
		address _owner,
		address _manager,
		uint256 _feePercent,
		uint64 _harvestDelay,
		uint128 _harvestWindow
	) external initializer {
		__ERC20_init(
			// ex: Scion USDC.e Vault
			string(abi.encodePacked("Scion ", ERC20(address(_UNDERLYING)).name(), " Vault")),
			// ex: sUSDC.e
			string(abi.encodePacked("sc", ERC20(address(_UNDERLYING)).symbol()))
		);

		__ReentrancyGuard_init();
		__Ownable_init();

		_decimals = ERC20(address(_UNDERLYING)).decimals();

		UNDERLYING = _UNDERLYING;

		BASE_UNIT = 10**_decimals;

		// configure
		setManager(_manager, true);
		setFeePercent(_feePercent);

		// delay must be set first
		setHarvestDelay(_harvestDelay);
		setHarvestWindow(_harvestWindow);

		emit Initialized(msg.sender);

		// must be call after all other inits
		_transferOwnership(_owner);

		// defaults to open vaults
		_maxTvl = type(uint256).max;
		_stratMaxTvl = type(uint256).max;
	}

	function decimals() public view override returns (uint8) {
		return uint8(_decimals);
	}

	/*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

	/// @notice The maximum number of elements allowed on the withdrawal stack.
	/// @dev Needed to prevent denial of service attacks by queue operators.
	uint256 internal constant MAX_WITHDRAWAL_STACK_SIZE = 32;

	/*///////////////////////////////////////////////////////////////
                                AUTH
    //////////////////////////////////////////////////////////////*/

	event ManagerUpdate(address indexed account, bool isManager);
	event AllowedUpdate(address indexed account, bool isManager);
	event SetPublic(bool setPublic);

	modifier requiresAuth() {
		require(msg.sender == owner() || isManager(msg.sender), "Vault: NO_AUTH");
		_;
	}

	mapping(address => bool) private _allowed;

	// Allowed (allow list for deposits)

	function isAllowed(address user) public view returns (bool) {
		return user == owner() || isManager(user) || _allowed[user];
	}

	function setAllowed(address user, bool _isManager) external requiresAuth {
		_allowed[user] = _isManager;
		emit AllowedUpdate(user, _isManager);
	}

	function bulkAllow(address[] memory users) external requiresAuth {
		for (uint256 i; i < users.length; i++) {
			_allowed[users[i]] = true;
			emit AllowedUpdate(users[i], true);
		}
	}

	modifier requireAllow() {
		require(_isPublic || isAllowed(msg.sender), "Vault: NOT_ON_ALLOW_LIST");
		_;
	}

	mapping(address => bool) private _managers;

	// GOVERNANCE - MANAGER
	function isManager(address user) public view returns (bool) {
		return _managers[user];
	}

	function setManager(address user, bool _isManager) public onlyOwner {
		_managers[user] = _isManager;
		emit ManagerUpdate(user, _isManager);
	}

	function isPublic() external view returns (bool) {
		return _isPublic;
	}

	function setPublic(bool isPublic_) external requiresAuth {
		_isPublic = isPublic_;
		emit SetPublic(isPublic_);
	}

	/*///////////////////////////////////////////////////////////////
                           FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

	/// @notice The percentage of profit recognized each harvest to reserve as fees.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public feePercent;

	/// @notice Emitted when the fee percentage is updated.
	/// @param user The authorized user who triggered the update.
	/// @param newFeePercent The new fee percentage.
	event FeePercentUpdated(address indexed user, uint256 newFeePercent);

	/// @notice Sets a new fee percentage.
	/// @param newFeePercent The new fee percentage.
	function setFeePercent(uint256 newFeePercent) public onlyOwner {
		// A fee percentage over 100% doesn't make sense.
		require(newFeePercent <= 1e18, "FEE_TOO_HIGH");

		// Update the fee percentage.
		feePercent = newFeePercent;

		emit FeePercentUpdated(msg.sender, newFeePercent);
	}

	/*///////////////////////////////////////////////////////////////
                        HARVEST CONFIGURATION
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted when the harvest window is updated.
	/// @param user The authorized user who triggered the update.
	/// @param newHarvestWindow The new harvest window.
	event HarvestWindowUpdated(address indexed user, uint128 newHarvestWindow);

	/// @notice Emitted when the harvest delay is updated.
	/// @param user The authorized user who triggered the update.
	/// @param newHarvestDelay The new harvest delay.
	event HarvestDelayUpdated(address indexed user, uint64 newHarvestDelay);

	/// @notice Emitted when the harvest delay is scheduled to be updated next harvest.
	/// @param user The authorized user who triggered the update.
	/// @param newHarvestDelay The scheduled updated harvest delay.
	event HarvestDelayUpdateScheduled(address indexed user, uint64 newHarvestDelay);

	/// @notice The period in seconds during which multiple harvests can occur
	/// regardless if they are taking place before the harvest delay has elapsed.
	/// @dev Long harvest windows open the Vault up to profit distribution slowdown attacks.
	uint128 public harvestWindow;

	/// @notice The period in seconds over which locked profit is unlocked.
	/// @dev Cannot be 0 as it opens harvests up to sandwich attacks.
	uint64 public harvestDelay;

	/// @notice The value that will replace harvestDelay next harvest.
	/// @dev In the case that the next delay is 0, no update will be applied.
	uint64 public nextHarvestDelay;

	/// @notice Sets a new harvest window.
	/// @param newHarvestWindow The new harvest window.
	/// @dev The Vault's harvestDelay must already be set before calling.
	function setHarvestWindow(uint128 newHarvestWindow) public onlyOwner {
		// A harvest window longer than the harvest delay doesn't make sense.
		require(newHarvestWindow <= harvestDelay, "WINDOW_TOO_LONG");

		// Update the harvest window.
		harvestWindow = newHarvestWindow;

		emit HarvestWindowUpdated(msg.sender, newHarvestWindow);
	}

	/// @notice Sets a new harvest delay.
	/// @param newHarvestDelay The new harvest delay to set.
	/// @dev If the current harvest delay is 0, meaning it has not
	/// been set before, it will be updated immediately, otherwise
	/// it will be scheduled to take effect after the next harvest.
	function setHarvestDelay(uint64 newHarvestDelay) public onlyOwner {
		// A harvest delay of 0 makes harvests vulnerable to sandwich attacks.
		require(newHarvestDelay != 0, "DELAY_CANNOT_BE_ZERO");

		// A harvest delay longer than 1 year doesn't make sense.
		require(newHarvestDelay <= 365 days, "DELAY_TOO_LONG");

		// If the harvest delay is 0, meaning it has not been set before:
		if (harvestDelay == 0) {
			// We'll apply the update immediately.
			harvestDelay = newHarvestDelay;

			emit HarvestDelayUpdated(msg.sender, newHarvestDelay);
		} else {
			// We'll apply the update next harvest.
			nextHarvestDelay = newHarvestDelay;

			emit HarvestDelayUpdateScheduled(msg.sender, newHarvestDelay);
		}
	}

	/*///////////////////////////////////////////////////////////////
                       TARGET FLOAT CONFIGURATION
    //////////////////////////////////////////////////////////////*/

	/// @notice The desired percentage of the Vault's holdings to keep as float.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public targetFloatPercent;

	/// @notice Emitted when the target float percentage is updated.
	/// @param user The authorized user who triggered the update.
	/// @param newTargetFloatPercent The new target float percentage.
	event TargetFloatPercentUpdated(address indexed user, uint256 newTargetFloatPercent);

	/// @notice Set a new target float percentage.
	/// @param newTargetFloatPercent The new target float percentage.
	function setTargetFloatPercent(uint256 newTargetFloatPercent) external onlyOwner {
		// A target float percentage over 100% doesn't make sense.
		require(newTargetFloatPercent <= 1e18, "TARGET_TOO_HIGH");

		// Update the target float percentage.
		targetFloatPercent = newTargetFloatPercent;

		emit TargetFloatPercentUpdated(msg.sender, newTargetFloatPercent);
	}

	/*///////////////////////////////////////////////////////////////
                   UNDERLYING IS WETH CONFIGURATION
    //////////////////////////////////////////////////////////////*/

	/// @notice Whether the Vault should treat the underlying token as WETH compatible.
	/// @dev If enabled the Vault will allow trusting strategies that accept Ether.
	bool public underlyingIsWETH;

	/// @notice Emitted when whether the Vault should treat the underlying as WETH is updated.
	/// @param user The authorized user who triggered the update.
	/// @param newUnderlyingIsWETH Whether the Vault nows treats the underlying as WETH.
	event UnderlyingIsWETHUpdated(address indexed user, bool newUnderlyingIsWETH);

	/// @notice Sets whether the Vault treats the underlying as WETH.
	/// @param newUnderlyingIsWETH Whether the Vault should treat the underlying as WETH.
	/// @dev The underlying token must have 18 decimals, to match Ether's decimal scheme.
	function setUnderlyingIsWETH(bool newUnderlyingIsWETH) external onlyOwner {
		// Ensure the underlying token's decimals match ETH.
		require(
			!newUnderlyingIsWETH || ERC20(address(UNDERLYING)).decimals() == 18,
			"WRONG_DECIMALS"
		);

		// Update whether the Vault treats the underlying as WETH.
		underlyingIsWETH = newUnderlyingIsWETH;

		emit UnderlyingIsWETHUpdated(msg.sender, newUnderlyingIsWETH);
	}

	/*///////////////////////////////////////////////////////////////
                          STRATEGY STORAGE
    //////////////////////////////////////////////////////////////*/

	/// @notice The total amount of underlying tokens held in strategies at the time of the last harvest.
	/// @dev Includes maxLockedProfit, must be correctly subtracted to compute available/free holdings.
	uint256 public totalStrategyHoldings;

	/// @dev Packed struct of strategy data.
	/// @param trusted Whether the strategy is trusted.
	/// @param balance The amount of underlying tokens held in the strategy.
	struct StrategyData {
		// Used to determine if the Vault will operate on a strategy.
		bool trusted;
		// Used to determine profit and loss during harvests of the strategy.
		uint248 balance;
	}

	/// @notice Maps strategies to data the Vault holds on them.
	mapping(Strategy => StrategyData) public getStrategyData;

	/*///////////////////////////////////////////////////////////////
                             HARVEST STORAGE
    //////////////////////////////////////////////////////////////*/

	/// @notice A timestamp representing when the first harvest in the most recent harvest window occurred.
	/// @dev May be equal to lastHarvest if there was/has only been one harvest in the most last/current window.
	uint64 public lastHarvestWindowStart;

	/// @notice A timestamp representing when the most recent harvest occurred.
	uint64 public lastHarvest;

	/// @notice The amount of locked profit at the end of the last harvest.
	uint128 public maxLockedProfit;

	/*///////////////////////////////////////////////////////////////
                        WITHDRAWAL QUEUE STORAGE
    //////////////////////////////////////////////////////////////*/

	/// @notice An ordered array of strategies representing the withdrawal queue.
	/// @dev The queue is processed in descending order, meaning the last index will be withdrawn from first.
	/// @dev Strategies that are untrusted, duplicated, or have no balance are filtered out when encountered at
	/// withdrawal time, not validated upfront, meaning the queue may not reflect the "true" set used for withdrawals.
	Strategy[] public withdrawalQueue;

	/// @notice Gets the full withdrawal queue.
	/// @return An ordered array of strategies representing the withdrawal queue.
	/// @dev This is provided because Solidity converts public arrays into index getters,
	/// but we need a way to allow external contracts and users to access the whole array.
	function getWithdrawalQueue() external view returns (Strategy[] memory) {
		return withdrawalQueue;
	}

	/*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted after a successful deposit.
	/// @param user The address that deposited into the Vault.
	/// @param underlyingAmount The amount of underlying tokens that were deposited.
	event Deposit(address indexed user, uint256 underlyingAmount);

	/// @notice Emitted after a successful withdrawal.
	/// @param user The address that withdrew from the Vault.
	/// @param underlyingAmount The amount of underlying tokens that were withdrawn.
	event Withdraw(address indexed user, uint256 underlyingAmount);

	/// @notice Deposit a specific amount of underlying tokens.
	/// @param underlyingAmount The amount of the underlying token to deposit.
	function deposit(uint256 underlyingAmount) external requireAllow {
		// you should not be able to deposit funds over the tvl limit
		require(underlyingAmount + totalHoldings() <= getMaxTvl(), "OVER_MAX_TVL");

		// Determine the equivalent amount of rvTokens and mint them.
		_mint(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

		emit Deposit(msg.sender, underlyingAmount);

		// Transfer in underlying tokens from the user.
		// This will revert if the user does not have the amount specified.
		UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);
	}

	/// @notice Withdraw a specific amount of underlying tokens.
	/// @param underlyingAmount The amount of underlying tokens to withdraw.
	function withdraw(uint256 underlyingAmount) external {
		// Determine the equivalent amount of rvTokens and burn them.
		// This will revert if the user does not have enough rvTokens.
		_burn(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

		emit Withdraw(msg.sender, underlyingAmount);

		// Withdraw from strategies if needed and transfer.
		transferUnderlyingTo(msg.sender, underlyingAmount);
	}

	/// @notice Redeem a specific amount of rvTokens for underlying tokens.
	/// @param rvTokenAmount The amount of rvTokens to redeem for underlying tokens.
	function redeem(uint256 rvTokenAmount) external {
		// Determine the equivalent amount of underlying tokens.
		uint256 underlyingAmount = rvTokenAmount.fmul(exchangeRate(), BASE_UNIT);

		// Burn the provided amount of rvTokens.
		// This will revert if the user does not have enough rvTokens.
		_burn(msg.sender, rvTokenAmount);

		emit Withdraw(msg.sender, underlyingAmount);
		// Withdraw from strategies if needed and transfer.
		transferUnderlyingTo(msg.sender, underlyingAmount);
	}

	/// @dev Transfers a specific amount of underlying tokens held in strategies and/or float to a recipient.
	/// @dev Only withdraws from strategies if needed and maintains the target float percentage if possible.
	/// @param recipient The user to transfer the underlying tokens to.
	/// @param underlyingAmount The amount of underlying tokens to transfer.
	function transferUnderlyingTo(address recipient, uint256 underlyingAmount) internal {
		// Get the Vault's floating balance.
		uint256 float = totalFloat();

		// If the amount is greater than the float, withdraw from strategies.
		if (underlyingAmount > float) {
			// Compute the amount needed to reach our target float percentage.
			uint256 floatMissingForTarget = (totalHoldings() - underlyingAmount).fmul(
				targetFloatPercent,
				1e18
			);

			// Compute the bare minimum amount we need for this withdrawal.
			uint256 floatMissingForWithdrawal = underlyingAmount - float;

			// Pull enough to cover the withdrawal and reach our target float percentage.
			pullFromWithdrawalQueue(floatMissingForWithdrawal + floatMissingForTarget, float);
		}

		// Transfer the provided amount of underlying tokens.
		UNDERLYING.safeTransfer(recipient, underlyingAmount);
	}

	/*///////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Returns a user's Vault balance in underlying tokens.
	/// @param user The user to get the underlying balance of.
	/// @return The user's Vault balance in underlying tokens.
	function balanceOfUnderlying(address user) external view returns (uint256) {
		return balanceOf(user).fmul(exchangeRate(), BASE_UNIT);
	}

	/// @notice Returns the amount of underlying tokens an rvToken can be redeemed for.
	/// @return The amount of underlying tokens an rvToken can be redeemed for.
	function exchangeRate() public view returns (uint256) {
		// Get the total supply of rvTokens.
		uint256 rvTokenSupply = totalSupply();

		// If there are no rvTokens in circulation, return an exchange rate of 1:1.
		if (rvTokenSupply == 0) return BASE_UNIT;

		// Calculate the exchange rate by dividing the total holdings by the rvToken supply.
		return totalHoldings().fdiv(rvTokenSupply, BASE_UNIT);
	}

	/// @notice Calculates the total amount of underlying tokens the Vault holds.
	/// @return totalUnderlyingHeld The total amount of underlying tokens the Vault holds.
	function totalHoldings() public view returns (uint256 totalUnderlyingHeld) {
		unchecked {
			// Cannot underflow as locked profit can't exceed total strategy holdings.
			totalUnderlyingHeld = totalStrategyHoldings - lockedProfit();
		}

		// Include our floating balance in the total.
		totalUnderlyingHeld += totalFloat();
	}

	/// @notice Calculates the current amount of locked profit.
	/// @return The current amount of locked profit.
	function lockedProfit() public view returns (uint256) {
		// Get the last harvest and harvest delay.
		uint256 previousHarvest = lastHarvest;
		uint256 harvestInterval = harvestDelay;

		unchecked {
			// If the harvest delay has passed, there is no locked profit.
			// Cannot overflow on human timescales since harvestInterval is capped.
			if (block.timestamp >= previousHarvest + harvestInterval) return 0;

			// Get the maximum amount we could return.
			uint256 maximumLockedProfit = maxLockedProfit;

			// TODO potentially better lock? https://github.com/yearn/yearn-vaults/pull/471/files

			// Compute how much profit remains locked based on the last harvest and harvest delay.
			// It's impossible for the previous harvest to be in the future, so this will never underflow.
			return
				maximumLockedProfit -
				(maximumLockedProfit * (block.timestamp - previousHarvest)) /
				harvestInterval;
		}
	}

	/// @notice Returns the amount of underlying tokens that idly sit in the Vault.
	/// @return The amount of underlying tokens that sit idly in the Vault.
	function totalFloat() public view returns (uint256) {
		return UNDERLYING.balanceOf(address(this));
	}

	/*///////////////////////////////////////////////////////////////
                             HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted after a successful harvest.
	/// @param user The authorized user who triggered the harvest.
	/// @param strategies The trusted strategies that were harvested.
	event Harvest(address indexed user, Strategy[] strategies);

	/// @notice Harvest a set of trusted strategies.
	/// @param strategies The trusted strategies to harvest.
	/// @dev Will always revert if called outside of an active
	/// harvest window or before the harvest delay has passed.
	function harvest(Strategy[] calldata strategies) external requiresAuth {
		// If this is the first harvest after the last window:
		if (block.timestamp >= lastHarvest + harvestDelay) {
			// Set the harvest window's start timestamp.
			// Cannot overflow 64 bits on human timescales.
			lastHarvestWindowStart = uint64(block.timestamp);
		} else {
			// We know this harvest is not the first in the window so we need to ensure it's within it.
			require(block.timestamp <= lastHarvestWindowStart + harvestWindow, "BAD_HARVEST_TIME");
		}

		// Get the Vault's current total strategy holdings.
		uint256 oldTotalStrategyHoldings = totalStrategyHoldings;

		// Used to store the total profit accrued by the strategies.
		uint256 totalProfitAccrued;

		// Used to store the new total strategy holdings after harvesting.
		uint256 newTotalStrategyHoldings = oldTotalStrategyHoldings;

		// Will revert if any of the specified strategies are untrusted.
		for (uint256 i = 0; i < strategies.length; i++) {
			// Get the strategy at the current index.
			Strategy strategy = strategies[i];

			// If an untrusted strategy could be harvested a malicious user could use
			// a fake strategy that over-reports holdings to manipulate the exchange rate.
			require(getStrategyData[strategy].trusted, "UNTRUSTED_STRATEGY");

			// Get the strategy's previous and current balance.
			uint256 balanceLastHarvest = getStrategyData[strategy].balance;
			uint256 balanceThisHarvest = strategy.balanceOfUnderlying(address(this));

			// Update the strategy's stored balance. Cast overflow is unrealistic.
			getStrategyData[strategy].balance = balanceThisHarvest.safeCastTo248();

			// Increase/decrease newTotalStrategyHoldings based on the profit/loss registered.
			// We cannot wrap the subtraction in parenthesis as it would underflow if the strategy had a loss.
			newTotalStrategyHoldings =
				newTotalStrategyHoldings +
				balanceThisHarvest -
				balanceLastHarvest;

			unchecked {
				// Update the total profit accrued while counting losses as zero profit.
				// Cannot overflow as we already increased total holdings without reverting.
				totalProfitAccrued += balanceThisHarvest > balanceLastHarvest
					? balanceThisHarvest - balanceLastHarvest // Profits since last harvest.
					: 0; // If the strategy registered a net loss we don't have any new profit.
			}
		}

		// Compute fees as the fee percent multiplied by the profit.
		uint256 feesAccrued = totalProfitAccrued.fmul(feePercent, 1e18);

		// If we accrued any fees, mint an equivalent amount of rvTokens.
		// Authorized users can claim the newly minted rvTokens via claimFees.
		_mint(address(this), feesAccrued.fdiv(exchangeRate(), BASE_UNIT));

		// Update max unlocked profit based on any remaining locked profit plus new profit.
		maxLockedProfit = (lockedProfit() + totalProfitAccrued - feesAccrued).safeCastTo128();

		// Set strategy holdings to our new total.
		totalStrategyHoldings = newTotalStrategyHoldings;

		// Update the last harvest timestamp.
		// Cannot overflow on human timescales.
		lastHarvest = uint64(block.timestamp);

		emit Harvest(msg.sender, strategies);

		// Get the next harvest delay.
		uint64 newHarvestDelay = nextHarvestDelay;

		// If the next harvest delay is not 0:
		if (newHarvestDelay != 0) {
			// Update the harvest delay.
			harvestDelay = newHarvestDelay;

			// Reset the next harvest delay.
			nextHarvestDelay = 0;

			emit HarvestDelayUpdated(msg.sender, newHarvestDelay);
		}
	}

	/*///////////////////////////////////////////////////////////////
                    MAX TVL LOGIC
    //////////////////////////////////////////////////////////////*/

	function getMaxTvl() public view returns (uint256 maxTvl) {
		return min(_maxTvl, _stratMaxTvl);
	}

	function setMaxTvl(uint256 maxTvl_) public requiresAuth {
		_maxTvl = maxTvl_;
	}

	// TODO should this just be a view computed on demand?
	function updateStratTvl() public requiresAuth returns (uint256 maxTvl) {
		for (uint256 i; i < withdrawalQueue.length; i++) {
			Strategy strategy = withdrawalQueue[i];
			uint256 stratTvl = strategy.getMaxTvl();
			// don't let new max overflow
			unchecked {
				maxTvl = maxTvl > maxTvl + stratTvl ? maxTvl : maxTvl + stratTvl;
			}
		}
		_stratMaxTvl = maxTvl;
	}

	/*///////////////////////////////////////////////////////////////
                    STRATEGY DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted after the Vault deposits into a strategy contract.
	/// @param user The authorized user who triggered the deposit.
	/// @param strategy The strategy that was deposited into.
	/// @param underlyingAmount The amount of underlying tokens that were deposited.
	event StrategyDeposit(
		address indexed user,
		Strategy indexed strategy,
		uint256 underlyingAmount
	);

	/// @notice Emitted after the Vault withdraws funds from a strategy contract.
	/// @param user The authorized user who triggered the withdrawal.
	/// @param strategy The strategy that was withdrawn from.
	/// @param underlyingAmount The amount of underlying tokens that were withdrawn.
	event StrategyWithdrawal(
		address indexed user,
		Strategy indexed strategy,
		uint256 underlyingAmount
	);

	/// @notice Deposit a specific amount of float into a trusted strategy.
	/// @param strategy The trusted strategy to deposit into.
	/// @param underlyingAmount The amount of underlying tokens in float to deposit.
	function depositIntoStrategy(Strategy strategy, uint256 underlyingAmount) public requiresAuth {
		// A strategy must be trusted before it can be deposited into.
		require(getStrategyData[strategy].trusted, "UNTRUSTED_STRATEGY");

		// We don't allow depositing 0 to prevent emitting a useless event.
		require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

		// Increase totalStrategyHoldings to account for the deposit.
		totalStrategyHoldings += underlyingAmount;

		unchecked {
			// Without this the next harvest would count the deposit as profit.
			// Cannot overflow as the balance of one strategy can't exceed the sum of all.
			getStrategyData[strategy].balance += underlyingAmount.safeCastTo248();
		}

		emit StrategyDeposit(msg.sender, strategy, underlyingAmount);

		// We need to deposit differently if the strategy takes ETH.
		if (strategy.isCEther()) {
			// Unwrap the right amount of WETH.
			IWETH(payable(address(UNDERLYING))).withdraw(underlyingAmount);

			// Deposit into the strategy and assume it will revert on error.
			ETHStrategy(address(strategy)).mint{ value: underlyingAmount }();
		} else {
			// Approve underlyingAmount to the strategy so we can deposit.
			UNDERLYING.safeApprove(address(strategy), underlyingAmount);

			// Deposit into the strategy and revert if it returns an error code.
			require(ERC20Strategy(address(strategy)).mint(underlyingAmount) == 0, "MINT_FAILED");
		}
	}

	/// @notice Withdraw a specific amount of underlying tokens from a strategy.
	/// @param strategy The strategy to withdraw from.
	/// @param underlyingAmount  The amount of underlying tokens to withdraw.
	/// @dev Withdrawing from a strategy will not remove it from the withdrawal queue.
	function withdrawFromStrategy(Strategy strategy, uint256 underlyingAmount) public requiresAuth {
		// A strategy must be trusted before it can be withdrawn from.
		require(getStrategyData[strategy].trusted, "UNTRUSTED_STRATEGY");

		// We don't allow withdrawing 0 to prevent emitting a useless event.
		require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

		// Without this the next harvest would count the withdrawal as a loss.
		getStrategyData[strategy].balance -= underlyingAmount.safeCastTo248();

		unchecked {
			// Decrease totalStrategyHoldings to account for the withdrawal.
			// Cannot underflow as the balance of one strategy will never exceed the sum of all.
			totalStrategyHoldings -= underlyingAmount;
		}

		emit StrategyWithdrawal(msg.sender, strategy, underlyingAmount);

		// Withdraw from the strategy and revert if it returns an error code.
		require(strategy.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

		// Wrap the withdrawn Ether into WETH if necessary.
		if (strategy.isCEther())
			IWETH(payable(address(UNDERLYING))).deposit{ value: underlyingAmount }();
	}

	/*///////////////////////////////////////////////////////////////
                      STRATEGY TRUST/DISTRUST LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted when a strategy is set to trusted.
	/// @param user The authorized user who trusted the strategy.
	/// @param strategy The strategy that became trusted.
	event StrategyTrusted(address indexed user, Strategy indexed strategy);

	/// @notice Emitted when a strategy is set to untrusted.
	/// @param user The authorized user who untrusted the strategy.
	/// @param strategy The strategy that became untrusted.
	event StrategyDistrusted(address indexed user, Strategy indexed strategy);

	/// @notice Helper method to add strategy and push it to the que in one tx.
	/// @param strategy The strategy to add.
	function addStrategy(Strategy strategy) public onlyOwner {
		trustStrategy(strategy);
		pushToWithdrawalQueue(strategy);
		updateStratTvl();
	}

	/// @notice Helper method to migrate strategy to a new implementation.
	/// @param prevStrategy The strategy to remove.
	/// @param newStrategy The strategy to add.
	function migrateStrategy(
		Strategy prevStrategy,
		Strategy newStrategy,
		uint256 queueIndex
	) public onlyOwner {
		trustStrategy(newStrategy);
		// make sure to call harvest before migrate
		uint256 stratBalance = getStrategyData[prevStrategy].balance;
		if (stratBalance > 0) {
			withdrawFromStrategy(prevStrategy, stratBalance);
			depositIntoStrategy(
				newStrategy,
				// we may end up with slightly less balance because of tx costs
				min(UNDERLYING.balanceOf(address(this)), stratBalance)
			);
		}
		if (queueIndex < withdrawalQueue.length)
			replaceWithdrawalQueueIndex(queueIndex, newStrategy);
		else pushToWithdrawalQueue(newStrategy);
		distrustStrategy(prevStrategy);
	}

	/// @notice Stores a strategy as trusted, enabling it to be harvested.
	/// @param strategy The strategy to make trusted.
	function trustStrategy(Strategy strategy) public onlyOwner {
		// Ensure the strategy accepts the correct underlying token.
		// If the strategy accepts ETH the Vault should accept WETH, it'll handle wrapping when necessary.
		require(
			strategy.isCEther()
				? underlyingIsWETH
				: ERC20Strategy(address(strategy)).underlying() == UNDERLYING,
			"WRONG_UNDERLYING"
		);

		// Store the strategy as trusted.
		getStrategyData[strategy].trusted = true;

		emit StrategyTrusted(msg.sender, strategy);
	}

	/// @notice Stores a strategy as untrusted, disabling it from being harvested.
	/// @param strategy The strategy to make untrusted.
	function distrustStrategy(Strategy strategy) public onlyOwner {
		// Store the strategy as untrusted.
		getStrategyData[strategy].trusted = false;

		emit StrategyDistrusted(msg.sender, strategy);
	}

	/*///////////////////////////////////////////////////////////////
                         WITHDRAWAL QUEUE LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted when a strategy is pushed to the withdrawal queue.
	/// @param user The authorized user who triggered the push.
	/// @param pushedStrategy The strategy pushed to the withdrawal queue.
	event WithdrawalQueuePushed(address indexed user, Strategy indexed pushedStrategy);

	/// @notice Emitted when a strategy is popped from the withdrawal queue.
	/// @param user The authorized user who triggered the pop.
	/// @param poppedStrategy The strategy popped from the withdrawal queue.
	event WithdrawalQueuePopped(address indexed user, Strategy indexed poppedStrategy);

	/// @notice Emitted when the withdrawal queue is updated.
	/// @param user The authorized user who triggered the set.
	/// @param replacedWithdrawalQueue The new withdrawal queue.
	event WithdrawalQueueSet(address indexed user, Strategy[] replacedWithdrawalQueue);

	/// @notice Emitted when an index in the withdrawal queue is replaced.
	/// @param user The authorized user who triggered the replacement.
	/// @param index The index of the replaced strategy in the withdrawal queue.
	/// @param replacedStrategy The strategy in the withdrawal queue that was replaced.
	/// @param replacementStrategy The strategy that overrode the replaced strategy at the index.
	event WithdrawalQueueIndexReplaced(
		address indexed user,
		uint256 index,
		Strategy indexed replacedStrategy,
		Strategy indexed replacementStrategy
	);

	/// @notice Emitted when an index in the withdrawal queue is replaced with the tip.
	/// @param user The authorized user who triggered the replacement.
	/// @param index The index of the replaced strategy in the withdrawal queue.
	/// @param replacedStrategy The strategy in the withdrawal queue replaced by the tip.
	/// @param previousTipStrategy The previous tip of the queue that replaced the strategy.
	event WithdrawalQueueIndexReplacedWithTip(
		address indexed user,
		uint256 index,
		Strategy indexed replacedStrategy,
		Strategy indexed previousTipStrategy
	);

	/// @notice Emitted when the strategies at two indexes are swapped.
	/// @param user The authorized user who triggered the swap.
	/// @param index1 One index involved in the swap
	/// @param index2 The other index involved in the swap.
	/// @param newStrategy1 The strategy (previously at index2) that replaced index1.
	/// @param newStrategy2 The strategy (previously at index1) that replaced index2.
	event WithdrawalQueueIndexesSwapped(
		address indexed user,
		uint256 index1,
		uint256 index2,
		Strategy indexed newStrategy1,
		Strategy indexed newStrategy2
	);

	/// @dev Withdraw a specific amount of underlying tokens from strategies in the withdrawal queue.
	/// @param underlyingAmount The amount of underlying tokens to pull into float.
	/// @dev Automatically removes depleted strategies from the withdrawal queue.
	function pullFromWithdrawalQueue(uint256 underlyingAmount, uint256 float) internal {
		// We will update this variable as we pull from strategies.
		uint256 amountLeftToPull = underlyingAmount;

		// We'll start at the tip of the queue and traverse backwards.
		uint256 currentIndex = withdrawalQueue.length - 1;

		// Iterate in reverse so we pull from the queue in a "last in, first out" manner.
		// Will revert due to underflow if we empty the queue before pulling the desired amount.
		for (; ; currentIndex--) {
			// Get the strategy at the current queue index.
			Strategy strategy = withdrawalQueue[currentIndex];

			// Get the balance of the strategy before we withdraw from it.
			uint256 strategyBalance = getStrategyData[strategy].balance;

			// If the strategy is currently untrusted or was already depleted:
			if (!getStrategyData[strategy].trusted || strategyBalance == 0) {
				// Remove it from the queue.
				withdrawalQueue.pop();

				emit WithdrawalQueuePopped(msg.sender, strategy);

				// Move onto the next strategy.
				continue;
			}

			// We want to pull as much as we can from the strategy, but no more than we need.
			uint256 amountToPull = strategyBalance > amountLeftToPull
				? amountLeftToPull
				: strategyBalance;

			unchecked {
				emit StrategyWithdrawal(msg.sender, strategy, amountToPull);

				// Withdraw from the strategy and revert if returns an error code.
				require(strategy.redeemUnderlying(amountToPull) == 0, "REDEEM_FAILED");

				// Cache the Vault's balance of ETH.
				if (underlyingIsWETH) {
					uint256 ethBalance = address(this).balance;
					if (ethBalance != 0)
						// If the Vault's underlying token is WETH compatible and we have some ETH, wrap it into WETH.
						IWETH(payable(address(UNDERLYING))).deposit{ value: ethBalance }();
				}

				// the actual amount we withdraw may be less than what we tried (tx fees)
				uint256 underlyingBalance = totalFloat();
				uint256 withdrawn = totalFloat() - float; // impossible for float to decrease
				float = underlyingBalance;

				// Compute the balance of the strategy that will remain after we withdraw.
				// Cannot underflow as we cap the amount to pull at the strategy's balance.
				uint256 strategyBalanceAfterWithdrawal = strategyBalance > withdrawn
					? strategyBalance - withdrawn
					: 0;

				// Without this the next harvest would count the withdrawal as a loss.
				getStrategyData[strategy].balance = strategyBalanceAfterWithdrawal.safeCastTo248();

				// Adjust our goal based on how much we can pull from the strategy.
				// Cannot underflow as we cap the amount to pull at the amount left to pull.
				amountLeftToPull = amountLeftToPull > withdrawn ? amountLeftToPull - withdrawn : 0;

				// If we fully depleted the strategy:
				if (strategyBalanceAfterWithdrawal == 0) {
					// Remove it from the queue.
					withdrawalQueue.pop();

					emit WithdrawalQueuePopped(msg.sender, strategy);
				}
			}

			// If we've pulled all we need, exit the loop.
			if (amountLeftToPull == 0) break;
		}

		unchecked {
			// Account for the withdrawals done in the loop above.
			// Cannot underflow as the balances of some strategies cannot exceed the sum of all.
			totalStrategyHoldings -= underlyingAmount;
		}
	}

	/// @notice Pushes a single strategy to front of the withdrawal queue.
	/// @param strategy The strategy to be inserted at the front of the withdrawal queue.
	/// @dev Strategies that are untrusted, duplicated, or have no balance are
	/// filtered out when encountered at withdrawal time, not validated upfront.
	function pushToWithdrawalQueue(Strategy strategy) public requiresAuth {
		// Ensure pushing the strategy will not cause the queue to exceed its limit.
		require(withdrawalQueue.length < MAX_WITHDRAWAL_STACK_SIZE, "STACK_FULL");

		// Push the strategy to the front of the queue.
		withdrawalQueue.push(strategy);

		emit WithdrawalQueuePushed(msg.sender, strategy);
	}

	/// @notice Removes the strategy at the tip of the withdrawal queue.
	/// @dev Be careful, another authorized user could push a different strategy
	/// than expected to the queue while a popFromWithdrawalQueue transaction is pending.
	function popFromWithdrawalQueue() external requiresAuth {
		// Get the (soon to be) popped strategy.
		Strategy poppedStrategy = withdrawalQueue[withdrawalQueue.length - 1];

		// Pop the first strategy in the queue.
		withdrawalQueue.pop();

		emit WithdrawalQueuePopped(msg.sender, poppedStrategy);
	}

	/// @notice Sets a new withdrawal queue.
	/// @param newQueue The new withdrawal queue.
	/// @dev Strategies that are untrusted, duplicated, or have no balance are
	/// filtered out when encountered at withdrawal time, not validated upfront.
	function setWithdrawalQueue(Strategy[] calldata newQueue) external requiresAuth {
		// Ensure the new queue is not larger than the maximum stack size.
		require(newQueue.length <= MAX_WITHDRAWAL_STACK_SIZE, "STACK_TOO_BIG");

		// Replace the withdrawal queue.
		withdrawalQueue = newQueue;

		emit WithdrawalQueueSet(msg.sender, newQueue);
	}

	/// @notice Replaces an index in the withdrawal queue with another strategy.
	/// @param index The index in the queue to replace.
	/// @param replacementStrategy The strategy to override the index with.
	/// @dev Strategies that are untrusted, duplicated, or have no balance are
	/// filtered out when encountered at withdrawal time, not validated upfront.
	function replaceWithdrawalQueueIndex(uint256 index, Strategy replacementStrategy)
		public
		requiresAuth
	{
		// Get the (soon to be) replaced strategy.
		Strategy replacedStrategy = withdrawalQueue[index];

		// Update the index with the replacement strategy.
		withdrawalQueue[index] = replacementStrategy;

		emit WithdrawalQueueIndexReplaced(msg.sender, index, replacedStrategy, replacementStrategy);
	}

	/// @notice Moves the strategy at the tip of the queue to the specified index and pop the tip off the queue.
	/// @param index The index of the strategy in the withdrawal queue to replace with the tip.
	function replaceWithdrawalQueueIndexWithTip(uint256 index) external requiresAuth {
		// Get the (soon to be) previous tip and strategy we will replace at the index.
		Strategy previousTipStrategy = withdrawalQueue[withdrawalQueue.length - 1];
		Strategy replacedStrategy = withdrawalQueue[index];

		// Replace the index specified with the tip of the queue.
		withdrawalQueue[index] = previousTipStrategy;

		// Remove the now duplicated tip from the array.
		withdrawalQueue.pop();

		emit WithdrawalQueueIndexReplacedWithTip(
			msg.sender,
			index,
			replacedStrategy,
			previousTipStrategy
		);
	}

	/// @notice Swaps two indexes in the withdrawal queue.
	/// @param index1 One index involved in the swap
	/// @param index2 The other index involved in the swap.
	function swapWithdrawalQueueIndexes(uint256 index1, uint256 index2) external requiresAuth {
		// Get the (soon to be) new strategies at each index.
		Strategy newStrategy2 = withdrawalQueue[index1];
		Strategy newStrategy1 = withdrawalQueue[index2];

		// Swap the strategies at both indexes.
		withdrawalQueue[index1] = newStrategy1;
		withdrawalQueue[index2] = newStrategy2;

		emit WithdrawalQueueIndexesSwapped(msg.sender, index1, index2, newStrategy1, newStrategy2);
	}

	/*///////////////////////////////////////////////////////////////
                         SEIZE STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted after a strategy is seized.
	/// @param user The authorized user who triggered the seize.
	/// @param strategy The strategy that was seized.
	event StrategySeized(address indexed user, Strategy indexed strategy);

	/// @notice Seizes a strategy.
	/// @param strategy The strategy to seize.
	/// @dev Intended for use in emergencies or other extraneous situations where the
	/// strategy requires interaction outside of the Vault's standard operating procedures.
	function seizeStrategy(Strategy strategy, IERC20[] calldata tokens) external requiresAuth {
		// Get the strategy's last reported balance of underlying tokens.
		uint256 strategyBalance = getStrategyData[strategy].balance;

		// attempt to withdraw all underlying first
		// this ensures manager cannot maliciously execute this method
		if (strategyBalance > 0) {
			try Strategy(strategy).redeemUnderlying(type(uint256).max) {} catch Error(
				string memory err
			) {
				// redeem may fail because of price mismatch - we want to revert seize in this case
				require(
					keccak256(abi.encodePacked((err))) !=
						keccak256(abi.encodePacked(("HLP: PRICE_MISMATCH"))),
					err
				);
			}
		}

		// If the strategy's balance exceeds the Vault's current
		// holdings, instantly unlock any remaining locked profit.
		if (strategyBalance > totalHoldings()) maxLockedProfit = 0;

		// Set the strategy's balance to 0.
		getStrategyData[strategy].balance = 0;

		unchecked {
			// Decrease totalStrategyHoldings to account for the seize.
			// Cannot underflow as the balance of one strategy will never exceed the sum of all.
			totalStrategyHoldings -= strategyBalance;
		}

		emit StrategySeized(msg.sender, strategy);

		// if there are any tokens left, transfer them to owner
		Strategy(strategy).emergencyWithdraw(owner(), tokens);
	}

	/*///////////////////////////////////////////////////////////////
                             FEE CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Emitted after fees are claimed.
	/// @param user The authorized user who claimed the fees.
	/// @param rvTokenAmount The amount of rvTokens that were claimed.
	event FeesClaimed(address indexed user, uint256 rvTokenAmount);

	/// @notice Claims fees accrued from harvests.
	/// @param rvTokenAmount The amount of rvTokens to claim.
	/// @dev Accrued fees are measured as rvTokens held by the Vault.
	function claimFees(uint256 rvTokenAmount) external requiresAuth {
		emit FeesClaimed(msg.sender, rvTokenAmount);

		// Transfer the provided amount of rvTokens to the caller.
		IERC20(address(this)).safeTransfer(msg.sender, rvTokenAmount);
	}

	/*///////////////////////////////////////////////////////////////
                          RECIEVE ETHER LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @dev Required for the Vault to receive unwrapped ETH.
	receive() external payable {}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/*///////////////////////////////////////////////////////////////
                          UPGRADE VARS
    //////////////////////////////////////////////////////////////*/

	uint256 private _maxTvl;
	uint256 private _stratMaxTvl;
	bool private _isPublic;
}