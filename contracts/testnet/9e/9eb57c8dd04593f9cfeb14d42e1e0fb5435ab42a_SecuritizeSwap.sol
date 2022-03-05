/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-04
*/

// File: contracts/utils/Initializable.sol

pragma solidity 0.8.12;

//SPDX-License-Identifier: UNLICENSED
contract Initializable {
    bool public initialized = false;

    modifier initializer() {
        require(!initialized, "Contract instance has already been initialized");

        _;

        initialized = true;
    }
}

// File: contracts/utils/CommonUtils.sol

pragma solidity 0.8.12;


library CommonUtils {
  enum IncDec { Increase, Decrease }

  function encodeString(string memory _str) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_str));
  }

  function isEqualString(string memory _str1, string memory _str2) internal pure returns (bool) {
    return encodeString(_str1) == encodeString(_str2);
  }

  function isEmptyString(string memory _str) internal pure returns (bool) {
    return isEqualString(_str, "");
  }
}

// File: contracts/omnibus/IDSOmnibusWalletController.sol

pragma solidity 0.8.12;


interface IDSOmnibusWalletController {
    function setAssetTrackingMode(uint8 _assetTrackingMode) external;

    function getAssetTrackingMode() external view returns (uint8);

    function isHolderOfRecord() external view returns (bool);

    function balanceOf(address _who) external view returns (uint256);

    function transfer(
        address _from,
        address _to,
        uint256 _value /*onlyOperator*/
    ) external;

    function deposit(
        address _to,
        uint256 _value /*onlyToken*/
    ) external;

    function withdraw(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;

    function seize(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;

    function burn(
        address _from,
        uint256 _value /*onlyToken*/
    ) external;
}

// File: contracts/registry/IDSRegistryService.sol

pragma solidity 0.8.12;




interface IDSRegistryService {

    function registerInvestor(
        string memory _id,
        string memory _collision_hash /*onlyExchangeOrAbove newInvestor(_id)*/
    ) external returns (bool);

    function updateInvestor(
        string memory _id,
        string memory _collisionHash,
        string memory _country,
        address[] memory _wallets,
        uint8[] memory _attributeIds,
        uint256[] memory _attributeValues,
        uint256[] memory _attributeExpirations /*onlyIssuerOrAbove*/
    ) external returns (bool);

    function removeInvestor(
        string memory _id /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function setCountry(
        string memory _id,
        string memory _country /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function getCountry(string memory _id) external view returns (string memory);

    function getCollisionHash(string memory _id) external view returns (string memory);

    function setAttribute(
        string memory _id,
        uint8 _attributeId,
        uint256 _value,
        uint256 _expiry,
        string memory _proofHash /*onlyExchangeOrAbove investorExists(_id)*/
    ) external returns (bool);

    function getAttributeValue(string memory _id, uint8 _attributeId) external view returns (uint256);

    function getAttributeExpiry(string memory _id, uint8 _attributeId) external view returns (uint256);

    function getAttributeProofHash(string memory _id, uint8 _attributeId) external view returns (string memory);

    function addWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove newWallet(_address)*/
    ) external returns (bool);

    function removeWallet(
        address _address,
        string memory _id /*onlyExchangeOrAbove walletExists walletBelongsToInvestor(_address, _id)*/
    ) external returns (bool);

    function addOmnibusWallet(
        string memory _id,
        address _omnibusWallet,
        IDSOmnibusWalletController _omnibusWalletController /*onlyIssuerOrAbove newOmnibusWallet*/
    ) external;

    function removeOmnibusWallet(
        string memory _id,
        address _omnibusWallet /*onlyIssuerOrAbove omnibusWalletControllerExists*/
    ) external;

    function getOmnibusWalletController(address _omnibusWallet) external view returns (IDSOmnibusWalletController);

    function isOmnibusWallet(address _omnibusWallet) external view returns (bool);

    function getInvestor(address _address) external view returns (string memory);

    function getInvestorDetails(address _address) external view returns (string memory, string memory);

    function getInvestorDetailsFull(string memory _id)
        external
        view
        returns (string memory, uint256[] memory, uint256[] memory, string memory, string memory, string memory, string memory);

    function isInvestor(string memory _id) external view returns (bool);

    function isWallet(address _address) external view returns (bool);

    function isAccreditedInvestor(string calldata _id) external view returns (bool);

    function isQualifiedInvestor(string calldata _id) external view returns (bool);

    function isAccreditedInvestor(address _wallet) external view returns (bool);

    function isQualifiedInvestor(address _wallet) external view returns (bool);

    function getInvestors(address _from, address _to) external view returns (string memory, string memory);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: contracts/token/IDSToken.sol

pragma solidity 0.8.12;





interface IDSToken is IERC20 {
    function getDSService(uint256 _serviceId) external view returns (address);
    /**
     * @dev Sets the total issuance cap
     * Note: The cap is compared to the total number of issued token, not the total number of tokens available,
     * So if a token is burned, it is not removed from the "total number of issued".
     * This call cannot be called again after it was called once.
     * @param _cap address The address which is going to receive the newly issued tokens
     */
    function setCap(
        uint256 _cap /*onlyMaster*/
    ) external;

    /******************************
       TOKEN ISSUANCE (MINTING)
   *******************************/

    /**
     * @dev Issues unlocked tokens
     * @param _to address The address which is going to receive the newly issued tokens
     * @param _value uint256 the value of tokens to issue
     * @return true if successful
     */
    function issueTokens(
        address _to,
        uint256 _value /*onlyIssuerOrAbove*/
    ) external returns (bool);

    /**
     * @dev Issuing tokens from the fund
     * @param _to address The address which is going to receive the newly issued tokens
     * @param _value uint256 the value of tokens to issue
     * @param _valueLocked uint256 value of tokens, from those issued, to lock immediately.
     * @param _reason reason for token locking
     * @param _releaseTime timestamp to release the lock (or 0 for locks which can only released by an unlockTokens call)
     * @return true if successful
     */
    function issueTokensCustom(
        address _to,
        uint256 _value,
        uint256 _issuanceTime,
        uint256 _valueLocked,
        string memory _reason,
        uint64 _releaseTime /*onlyIssuerOrAbove*/
    ) external returns (bool);

    function issueTokensWithMultipleLocks(
        address _to,
        uint256 _value,
        uint256 _issuanceTime,
        uint256[] memory _valuesLocked,
        string memory _reason,
        uint64[] memory _releaseTimes /*onlyIssuerOrAbove*/
    ) external returns (bool);

    //*********************
    // TOKEN BURNING
    //*********************

    function burn(
        address _who,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    function omnibusBurn(
        address _omnibusWallet,
        address _who,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    //*********************
    // TOKEN SIEZING
    //*********************

    function seize(
        address _from,
        address _to,
        uint256 _value,
        string memory _reason /*onlyIssuerOrAbove*/
    ) external;

    function omnibusSeize(
        address _omnibusWallet,
        address _from,
        address _to,
        uint256 _value,
        string memory _reason
        /*onlyIssuerOrAbove*/
    ) external;

    //*********************
    // WALLET ENUMERATION
    //*********************

    function getWalletAt(uint256 _index) external view returns (address);

    function walletCount() external view returns (uint256);

    //**************************************
    // MISCELLANEOUS FUNCTIONS
    //**************************************
    function isPaused() external view returns (bool);

    function balanceOfInvestor(string memory _id) external view returns (uint256);

    function updateOmnibusInvestorBalance(
        address _omnibusWallet,
        address _wallet,
        uint256 _value,
        CommonUtils.IncDec _increase /*onlyOmnibusWalletController*/
    ) external returns (bool);

    function emitOmnibusTransferEvent(
        address _omnibusWallet,
        address _from,
        address _to,
        uint256 _value /*onlyOmnibusWalletController*/
    ) external;

    function emitOmnibusTBEEvent(address omnibusWallet, int256 totalDelta, int256 accreditedDelta,
        int256 usAccreditedDelta, int256 usTotalDelta, int256 jpTotalDelta /*onlyTBEOmnibus*/
    ) external;

    function emitOmnibusTBETransferEvent(address omnibusWallet, string memory externalId) external;

    function preTransferCheck(address _from, address _to, uint256 _value) external view returns (uint256 code, string memory reason);
}

// File: contracts/trust/IDSTrustService.sol

pragma solidity 0.8.12;

/**
 * @title IDSTrustService
 * @dev An interface for a trust service which allows role-based access control for other contracts.
 */

interface IDSTrustService {
    /**
     * @dev Transfers the ownership (MASTER role) of the contract.
     * @param _address The address which the ownership needs to be transferred to.
     * @return A boolean that indicates if the operation was successful.
     */
    function setServiceOwner(
        address _address /*onlyMaster*/
    ) external returns (bool);

    /**
     * @dev Sets a role for a wallet.
     * @dev Should not be used for setting MASTER (use setServiceOwner) or role removal (use removeRole).
     * @param _address The wallet whose role needs to be set.
     * @param _role The role to be set.
     * @return A boolean that indicates if the operation was successful.
     */
    function setRole(
        address _address,
        uint8 _role /*onlyMasterOrIssuer*/
    ) external returns (bool);

    /**
     * @dev Removes the role for a wallet.
     * @dev Should not be used to remove MASTER (use setServiceOwner).
     * @param _address The wallet whose role needs to be removed.
     * @return A boolean that indicates if the operation was successful.
     */
    function removeRole(
        address _address /*onlyMasterOrIssuer*/
    ) external returns (bool);

    /**
     * @dev Gets the role for a wallet.
     * @param _address The wallet whose role needs to be fetched.
     * @return A boolean that indicates if the operation was successful.
     */
    function getRole(address _address) external view returns (uint8);

    function addEntity(
        string memory _name,
        address _owner /*onlyMasterOrIssuer onlyNewEntity onlyNewEntityOwner*/
    ) external;

    function changeEntityOwner(
        string memory _name,
        address _oldOwner,
        address _newOwner /*onlyMasterOrIssuer onlyExistingEntityOwner*/
    ) external;

    function addOperator(
        string memory _name,
        address _operator /*onlyEntityOwnerOrAbove onlyNewOperator*/
    ) external;

    function removeOperator(
        string memory _name,
        address _operator /*onlyEntityOwnerOrAbove onlyExistingOperator*/
    ) external;

    function addResource(
        string memory _name,
        address _resource /*onlyMasterOrIssuer onlyExistingEntity onlyNewResource*/
    ) external;

    function removeResource(
        string memory _name,
        address _resource /*onlyMasterOrIssuer onlyExistingResource*/
    ) external;

    function getEntityByOwner(address _owner) external view returns (string memory);

    function getEntityByOperator(address _operator) external view returns (string memory);

    function getEntityByResource(address _resource) external view returns (string memory);

    function isResourceOwner(address _resource, address _owner) external view returns (bool);

    function isResourceOperator(address _resource, address _operator) external view returns (bool);
}

// File: contracts/swap/ISecuritizeSwap.sol

pragma solidity 0.8.12;





abstract contract ISecuritizeSwap {
    IDSToken public dsToken;
    IERC20 public usdcToken;
    IDSRegistryService public registryService;
    IDSTrustService public trustService;

    address public securitizeWallet;

    event Swap(
        address indexed _from,
        uint256 _dsTokenValue,
        uint256 _usdcValue,
        address indexed _newWalletTo
    );

    event DocumentSigned (
        address indexed _from,
        bytes32 _agreementHash
    );

    /**
     * @dev It does a swap between USDC ERC-20 token and DSToken.
     * @param _senderInvestorId investor sender (blockchainId). BlockchainId should be created by main-api
     * @param _valueDsToken tokens to mint to investor's new wallet
     * @param _valueUsdc send to Securitize's wallet
     * @param _deadLine timestamp when pre-approved transaction does not work anymore
     * @param _agreementHash hash of PDF document created before staring swap operation.
     */
    function swap(
        string memory _senderInvestorId,
        uint256 _valueDsToken,
        uint256 _valueUsdc,
        uint256 _deadLine,
        bytes32 _agreementHash
    ) external virtual;

    /**
     * @dev Validates off-chain signatures and executes transaction.
     * @param sigV V signature
     * @param sigR R signature
     * @param sigR R signature
     * @param senderInvestor investor id created by registryService
     * @param destination address
     * @param data encoded transaction data. For example issue token
     * @param params array of params. params[0] = value, params[1] = gasLimit, params[2] = blockLimit
     */
    function executePreApprovedTransaction(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        string memory senderInvestor,
        address destination,
        address executor,
        bytes memory data,
        uint256[] memory params
    ) virtual public;
}

// File: contracts/utils/SecuritizeConstants.sol

pragma solidity 0.8.12;


abstract contract SecuritizeConstants {
    // Trust service constantes
    uint8 public constant ROLE_MASTER = 1;
    uint8 public constant ROLE_ISSUER = 2;

    //RegistryService constants
    uint8 public constant NONE = 0;
    uint8 public constant KYC_APPROVED = 1;
    uint8 public constant ACCREDITED = 2;
    uint8 public constant QUALIFIED = 4;
    uint8 public constant PROFESSIONAL = 8;

    uint8 public constant PENDING = 0;
    uint8 public constant APPROVED = 1;
    uint8 public constant REJECTED = 2;
    uint8 public constant EXCHANGE = 4;

    uint256 public constant DS_TRUST_SERVICE = 1;
    uint256 public constant DS_REGISTRY_SERVICE = 4;

    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712_DOMAIN_TYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("SecuritizeSwap")
    bytes32 constant NAME_HASH = 0x5183e5178b4530d2fd10dfc0fff5d171f113e3becc98b45ca5513d6472888e3c;

    // keccak256("ExecutePreApprovedTransaction(string memory _senderInvestor, address _destination,address _executor,bytes _data, uint256[] memory _params)")
    bytes32 constant TXTYPE_HASH = 0xee963d66f92bd81c2e9b743fdab1cc81cd81a67f7626663992ce230ad0c71b51;

    //keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    bytes32 constant SALT = 0xc7c09cf61ec4558aac49f42b32ffbafd87af4676341e61db3c383153955f6f39;
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/swap/SecuritizeSwap.sol

pragma solidity 0.8.12;




contract SecuritizeSwap is ISecuritizeSwap, SecuritizeConstants, Initializable {
    using SafeMath for uint256;
    string public constant CONTRACT_VERSION = "1";

    bytes32 public DOMAIN_SEPARATOR;
    mapping(string => uint256) internal noncePerInvestor;

    function initialize(
        address _dsToken,
        address _usdc,
        address _securitizeWallet
    ) public {
        dsToken = IDSToken(_dsToken);
        usdcToken = IERC20(_usdc);
        securitizeWallet = _securitizeWallet;
        registryService = IDSRegistryService(dsToken.getDSService(DS_REGISTRY_SERVICE));
        trustService = IDSTrustService(dsToken.getDSService(DS_TRUST_SERVICE));

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                chainId,
                this,
                SALT
            )
        );
    }

    function swap(
        string memory _senderInvestorId,
        uint256 _valueDsToken,
        uint256 _valueUsdc,
        uint256 _blockLimit,
        bytes32 _agreementHash
    ) public override {
        address newInvestorWallet = msg.sender;
        require(_blockLimit >= block.number, 'Transaction too old');
        require(
            newInvestorWallet != address(trustService) &&
            newInvestorWallet != address(registryService) &&
            newInvestorWallet != address(usdcToken) &&
            newInvestorWallet != address(dsToken) &&
            newInvestorWallet != address(this), 'invalid newWallet address');
        require(usdcToken.balanceOf(newInvestorWallet) >= _valueUsdc, 'not enough USDC tokens balance');
        bool isSuccess = false;

        //Investor already exists
        if (registryService.isInvestor(_senderInvestorId)) {
            // Check if _newWallet is a new wallet
            string memory investorWithNewWallet = registryService.getInvestor(newInvestorWallet);
            if(CommonUtils.isEmptyString(investorWithNewWallet)) {
                isSuccess = registryService.addWallet(newInvestorWallet, _senderInvestorId);
                require(isSuccess, "addWallet failed");
            }
            //new wallet already exist. We need to check if it belongs to investor
            else {
                require(CommonUtils.isEqualString(_senderInvestorId, investorWithNewWallet) , 'new wallet does not belong to investor');
            }
        }
        //It is a new investor
        else {
            isSuccess = registryService.registerInvestor(_senderInvestorId, '');
            require(isSuccess, "create investor failed");

            isSuccess = registryService.addWallet(newInvestorWallet, _senderInvestorId);
            require(isSuccess, "addWallet failed");
        }

        isSuccess = usdcToken.transferFrom(msg.sender, securitizeWallet, _valueUsdc);
        require(isSuccess, "transferFrom failed");

        isSuccess = dsToken.issueTokensCustom(newInvestorWallet, _valueDsToken, block.timestamp, 0, "", 0);
        require(isSuccess, "issueTokens failed");

        emit DocumentSigned (msg.sender, _agreementHash);
        emit Swap(msg.sender, _valueDsToken, _valueUsdc, newInvestorWallet);
    }

    /**
     * @dev Validates off-chain signatures and executes transaction.
     * @param sigV V signature
     * @param sigR R signature
     * @param sigR R signature
     * @param senderInvestor investor id created by registryService
     * @param destination address
     * @param data encoded transaction data. For example issue token
     * @param params array of params. params[0] = value, params[1] = gasLimit, params[2] = blockLimit
     */
    function executePreApprovedTransaction(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        string memory senderInvestor,
        address destination,
        address executor,
        bytes memory data,
        uint256[] memory params
    ) public override {
        require(params.length == 3, "Incorrect params length");
        require(params[2] >= block.number, "Transaction too old");
        doExecuteByInvestor(sigV, sigR, sigS, senderInvestor, destination, data, executor, params);
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function doExecuteByInvestor(
        uint8 _securitizeHsmSigV,
        bytes32 _securitizeHsmSigR,
        bytes32 _securitizeHsmSigS,
        string memory _senderInvestorId,
        address _destination,
        bytes memory _data,
        address _executor,
        uint256[] memory _params
    ) private {
        bytes32 txInputHash = keccak256(
            abi.encode(
                TXTYPE_HASH,
                _destination,
                _params[0],
                keccak256(_data),
                noncePerInvestor[_senderInvestorId],
                _executor,
                _params[1],
                _params[2]
            )
        );
        bytes32 totalHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash)
        );

        address recovered = ecrecover(totalHash, _securitizeHsmSigV, _securitizeHsmSigR, _securitizeHsmSigS);
        // Check that the recovered address is an issuer
        uint256 approverRole = trustService.getRole(recovered);
        require(approverRole == ROLE_ISSUER || approverRole == ROLE_MASTER, 'sender without permissions');

        noncePerInvestor[_senderInvestorId] = noncePerInvestor[_senderInvestorId].add(1);
        bool success = false;
        uint256 value = _params[0];
        uint256 gasLimit = _params[1];
        assembly {
            success := call(
            gasLimit,
            _destination,
            value,
            add(_data, 0x20),
            mload(_data),
            0,
            0
            )
        }
        require(success, "transaction was not executed");
    }
}