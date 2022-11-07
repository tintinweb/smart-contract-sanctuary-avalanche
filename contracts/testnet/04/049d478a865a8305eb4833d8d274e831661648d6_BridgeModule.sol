// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// ============ Internal imports ============
import "./templates/GenericModule.sol";
import "../interfaces/IBridgeReceiver.sol";

// ============ External imports ============
import "@openzeppelin/contracts/access/Ownable.sol";
import {IInterchainGasPaymaster} from "@hyperlane-xyz/interfaces/IInterchainGasPaymaster.sol";
import {IOutbox} from "@hyperlane-xyz/interfaces/IOutbox.sol";
import {IAbacusConnectionManager} from "@hyperlane-xyz/interfaces/IAbacusConnectionManager.sol";
import {TypeCasts} from "@hyperlane-xyz/contracts/libs/TypeCasts.sol";

/// @notice Manages cross-chain YSS/YAMA transfers
contract BridgeModule is GenericModule {
  // ============ Variables ============
  IAbacusConnectionManager public connectionManager;
  // Interchain Gas Paymaster contract. The relayer associated with this contract
  // must be willing to relay messages dispatched from the current Outbox contract,
  // otherwise payments made to the paymaster will not result in relayed messages.
  IInterchainGasPaymaster public interchainGasPaymaster;

  // chainId => address
  mapping(uint32 => bytes32) public bridgeAddress;

  // chainId => (address => isBridge)
  mapping(uint32 => mapping(bytes32 => bool)) public altBridgeAddress;

  // ============ Events ============
  event RemoteTransferSent(
    address fromAddress,
    uint32 dstChainId,
    bytes32 toAddress,
    uint256 amount
  );

  event RemoteTransferReceived(
    bytes32 fromAddress,
    uint32 srcChainId,
    address toAddress,
    uint256 amount
  );

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from an Abacus Inbox contract
   */
  modifier onlyInbox() {
    require(_isInbox(msg.sender), "!inbox");
    _;
  }

  constructor(
    ModularToken _token,
    address _connectionManager,
    address _interchainGasPaymaster
  ) GenericModule(_token) {
    setHyperlaneParameters(_connectionManager, _interchainGasPaymaster);
  }

  // ============ External functions ============

  /// @notice Transfers YSS from the sender's wallet to a remote chain
  /// @param dstChainId The Hyperlane chain identifier of the remote chain
  /// @param toAddress The recipient's address on the remote chain.
  /// @param amount Amount of YSS to send.
  /// @param receiverPayload An arbitrary payload sent to the recipient callback
  function transferRemote(
    uint32 dstChainId,
    bytes32 toAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) external {
    sendRemoteTransfer(
      msg.sender,
      dstChainId,
      toAddress,
      amount,
      receiverPayload
    );
  }

  /// @notice Transfers YSS from the specified wallet to a remote chain
  /// @param fromAddress The wallet YSS is transferred from.
  /// @param dstChainId The Hyperlane chain identifier of the remote chain
  /// @param toAddress The recipient's address on the remote chain.
  /// @param amount Amount of YSS to send.
  /// @param receiverPayload An arbitrary payload sent to the recipient callback
  function transferFromRemote(
    address fromAddress,
    uint32 dstChainId,
    bytes32 toAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) public {
    uint256 allowance = token.allowance(fromAddress, msg.sender);
    require(allowance >= amount, "Bridge: Insufficient allowance");

    sendRemoteTransfer(
      fromAddress,
      dstChainId,
      toAddress,
      amount,
      receiverPayload
    );

    allowance -= amount;
    token.approve(fromAddress, msg.sender, allowance);
  }

  /// @notice Encodes cross-chain transfer data and sends it with Hyperlane
  /// @param fromAddress The wallet YSS is transferred from.
  /// @param dstChainId The Hyperlane chain identifier of the remote chain
  /// @param toAddress The recipient's address on the remote chain.
  /// @param amount Amount of YSS to send.
  /// @param receiverPayload An arbitrary payload sent to the recipient callback
  function sendRemoteTransfer(
    address fromAddress,
    uint32 dstChainId,
    bytes32 toAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) internal {
    token.burn(fromAddress, amount);

    bytes memory payload = encodePayload(
      fromAddress,
      toAddress,
      amount,
      receiverPayload
    );

    uint256 leafIndex = _outbox().dispatch(
      dstChainId,
      bridgeAddress[dstChainId],
      payload
    );
    interchainGasPaymaster.payGasFor{value:msg.value}(
      address(_outbox()),
      leafIndex,
      dstChainId
    );

    emit RemoteTransferSent(
      fromAddress,
      dstChainId,
      toAddress,
      amount
    );
  }

  /// @notice Calls the callback of an address receiving a cross-chain transfer
  /// @dev This is called in a try statement
  function callBridgeReceiver(
    address receiver,
    uint32 origin,
    bytes32 fromAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) external {
    require(msg.sender == address(this));
    IBridgeReceiver(receiver).yamaBridgeCallback(
      origin, fromAddress, amount, receiverPayload
    );
  }

  /// @notice Handles a cross-chain transfer.
  function handle(
    uint32 origin,
    bytes32 sender,
    bytes calldata payload
  ) external onlyInbox {
    require(sender == bridgeAddress[origin] || altBridgeAddress[origin][sender],
      "Bridge: Invalid sender address");
    
    (
      bytes32 fromAddress,
      address toAddress,
      uint256 amount,
      bytes calldata receiverPayload
    ) = decodePayload(payload);

    token.mint(toAddress, amount);

    try this.callBridgeReceiver(
      toAddress,
      origin,
      fromAddress,
      amount,
      receiverPayload
    ) {} catch {}

    emit RemoteTransferReceived(
      fromAddress,
      origin,
      toAddress,
      amount
    );
  }

  /// @notice Encodes data to send with Hyperlane
  /// @return payload The encoded data
  function encodePayload(
    address fromAddress,
    bytes32 toAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) public pure returns (bytes memory payload) {
    return abi.encodePacked(
      TypeCasts.addressToBytes32(fromAddress),
      toAddress,
      amount,
      receiverPayload
    );
  }

  /// @notice Decodes an encoded payload from Hyperlane
  function decodePayload(bytes calldata payload) public pure returns (
    bytes32 fromAddress,
    address toAddress,
    uint256 amount,
    bytes calldata receiverPayload
  ) {
    fromAddress = bytes32(payload[:32]);
    toAddress = TypeCasts.bytes32ToAddress(bytes32(payload[32:64]));
    amount = uint256(bytes32(payload[64:96]));
    receiverPayload = payload[96:];
  }

  /// @notice Sets the address of a bridge contract on another chain.
  /// @dev Sends messages to and accepts messages from that address
  function setBridge(
    uint32 chainId,
    bytes32 _bridgeAddress
  ) external onlyWhitelist {
    bridgeAddress[chainId] = _bridgeAddress;
  }

  /// @notice Sets an alternate remote bridge address to accept messages from
  /// @param chainId The Hyperlane chain identifier for the remote chain
  /// @param _altBridgeAddress The remote bridge address
  /// @param isAltBridge Whether this is a valid alternate remote bridge address
  function setAlternateBridge(
    uint32 chainId,
    bytes32 _altBridgeAddress,
    bool isAltBridge
  ) external onlyWhitelist{
    altBridgeAddress[chainId][_altBridgeAddress] = isAltBridge;
  }

  function setHyperlaneParameters(
    address _connectionManager,
    address _interchainGasPaymaster
  ) public onlyWhitelist {
    connectionManager = IAbacusConnectionManager(_connectionManager);
    interchainGasPaymaster = IInterchainGasPaymaster(_interchainGasPaymaster);
  }

  /**
   * @notice Determine whether _potentialInbox is an enrolled Inbox from the connectionManager
   * @return True if _potentialInbox is an enrolled Inbox
   */
  function _isInbox(address _potentialInbox) internal view returns (bool) {
    return connectionManager.isInbox(_potentialInbox);
  }

  /**
   * @notice Get the local Outbox contract from the connectionManager
   * @return outbox local Outbox contract
   */
  function _outbox() internal view returns (IOutbox) {
    return connectionManager.outbox();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../../ModularToken.sol";

abstract contract GenericModule {
  ModularToken public token;
  
  modifier onlyWhitelist() {
    require(token.whitelist(msg.sender));
    _;
  }

  constructor(ModularToken _token) {
    token = _token;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IBridgeReceiver {
  /// @notice Executes upon receiving bridged YSS/YAMA tokens
  /// @dev Make sure to check the YSS/YAMA bridge module is msg.sender
  /// @dev This is the same callback for the YAMA and YSS bridge.
  function yamaBridgeCallback(
    uint32 srcChainId,
    bytes32 fromAddress,
    uint256 amount,
    bytes calldata payload
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payGasFor(
        address _outbox,
        uint256 _leafIndex,
        uint32 _destinationDomain
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IMailbox} from "./IMailbox.sol";

interface IOutbox is IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);

    function cacheCheckpoint() external;

    function latestCheckpoint() external view returns (bytes32, uint256);

    function count() external returns (uint256);

    function fail() external;

    function cachedCheckpoints(bytes32) external view returns (uint256);

    function latestCachedCheckpoint()
        external
        view
        returns (bytes32 root, uint256 index);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IOutbox} from "./IOutbox.sol";

interface IAbacusConnectionManager {
    function outbox() external view returns (IOutbox);

    function isInbox(address _inbox) external view returns (bool);

    function localDomain() external view returns (uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf)
        internal
        pure
        returns (string memory _newStr)
    {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Template for modular tokens.
contract ModularToken is ERC20 {
  // Whitelisted addresses can mint/burn the token.
  mapping(address => bool) public whitelist;
  
  event SetWhitelist(address account, bool isWhitelisted);
  event SetEmergencyPause(bool value);

  /// @notice Restricts execution of a function to whitelisted EOAs/contracts
  modifier onlyWhitelist() {
    require(whitelist[msg.sender], "ModularToken: Sender not whitelisted");
    _;
  }

  constructor(
    uint256 mintAmount,
    string memory name,
    string memory symbol
  ) ERC20(name, symbol) {
    _mint(msg.sender, mintAmount);
    whitelist[msg.sender] = true;
    setWhitelist(msg.sender, true);
  }

  /// @notice Sets the whitelist status of an address
  function setWhitelist(
    address account,
    bool isWhitelisted
  ) public onlyWhitelist {
    whitelist[account] = isWhitelisted;

    emit SetWhitelist(account, isWhitelisted);
  }

  /// @notice Used by whitelisted contracts/EOAs to mint tokens
  /// @param account Address that receives tokens
  function mint(
    address account,
    uint256 amount
  ) external onlyWhitelist {
    _mint(account, amount);
  }

  /// @notice Used by whitelisted contracts/EOAs to burn tokens
  /// @param account Address where tokens are burned
  function burn(
    address account,
    uint256 amount
  ) external onlyWhitelist {
    _burn(account, amount);
  }

  /// @notice Used by whitelisted contracts/EOAs to modify token allowances 
  function approve(
    address owner,
    address spender,
    uint256 amount
  ) external onlyWhitelist {
    _approve(owner, spender, amount);
  }
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMailbox {
    function localDomain() external view returns (uint32);

    function validatorManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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