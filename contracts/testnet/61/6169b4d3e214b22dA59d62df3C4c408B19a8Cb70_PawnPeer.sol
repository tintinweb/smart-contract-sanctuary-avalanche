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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDiscountManager {
    function getDiscountRate(address collection, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTShipper {
    function transferNFT(address collection, address from,
        address to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenIdentifier {
    function isERC1155(address nftAddress) external returns (bool);
    function isERC721(address nftAddress) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DataTypes {
    struct Deal {
        uint256 dealId;
        address maker;
        address taker;
        address collection;
        uint256 tokenId;
        uint256 amount;
        uint256 dealPrice;
        uint256 acceptedTs;
        uint256 expiresTs;
        uint256 dailyInterest;
        bool closed;
    }

    struct Listing {
        address maker;
        address collection;
        uint256 tokenId;
        uint256 amount;
        uint256 askPrice;
        uint256 maxLockTime;
        uint256 expiresAt;
        uint256 dailyInterest;
        uint256 nonce;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct Offer {
        address taker;
        address collection;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 expiresAt;
        uint256 amount;
        bool collectionOffer;
        uint256 maxLockTime;
        uint256 dailyInterest;
        uint256 nonce;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hashListing(Listing memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("Listing(address maker,address collection,uint256 tokenId,uint256 amount,uint256 askPrice,uint256 maxLockTime,uint256 expiresAt,uint256 dailyInterest,uint256 nonce)"),
            order.maker,
            order.collection,
            order.tokenId,
            order.amount,
            order.askPrice,
            order.maxLockTime,
            order.expiresAt,
            order.dailyInterest,
            order.nonce
        ));
    }

    function hashOffer(Offer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("Offer(address taker,address collection,uint256 tokenId,uint256 bidPrice,uint256 expiresAt,uint256 amount,bool collectionOffer,uint256 maxLockTime,uint256 dailyInterest,uint256 nonce)"),
            offer.taker,
            offer.collection,
            offer.tokenId,
            offer.bidPrice,
            offer.expiresAt,
            offer.amount,
            offer.collectionOffer,
            offer.maxLockTime,
            offer.dailyInterest,
            offer.nonce
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {INFTShipper} from "./interfaces/INFTShipper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SignatureVerifier} from "./SignatureVerifier.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {IWAVAX} from "./interfaces/IWAVAX.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenIdentifier} from "./interfaces/ITokenIdentifier.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IDiscountManager} from "./interfaces/IDiscountManager.sol";

contract PawnPeer is SignatureVerifier, Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using DataTypes for DataTypes.Listing;
    using DataTypes for DataTypes.Offer;
    using DataTypes for DataTypes.Deal;

    address public paymentReceiver;
    address public wavaxAddress;
    address public nftShipperAddress;
    address public discountManagerAddress;

    uint256 public constant percentageMultiplier = 100;
    uint256 public platformFee;
    uint256 public minDailyInterest;
    uint256 public maxDailyInterest;

    mapping(address => uint256) public userMinNonce;
    mapping(address => mapping(uint256 => uint8)) private nonceExecutedOrCancelled;

    uint256 public nextDealId = 1;
    mapping(uint256 => DataTypes.Deal) public idToDeal;

    error Unauthorized();
    error InvalidSignature();
    error OutOfBounds();
    error InvalidPrice();
    error InsufficientPayment();
    error OrderExpired();
    error InvalidDeal();
    error UnsupportedTokenType();

    event NewDeal(DataTypes.Deal deal);
    event DealClosed(DataTypes.Deal deal);
    event CancelAllOrdersAndOffers(address user, uint256 minNonce);
    event CancelMultipleOrdersAndOffers(address user, uint256[] nonceList);

    constructor(address _wavaxAddress, address _paymentReceiver) {
        wavaxAddress = _wavaxAddress;
        paymentReceiver = _paymentReceiver;
        minDailyInterest = 5; // 0.05%
        maxDailyInterest = 50; // 0.5%
        platformFee = 250; // 2.5%
    }

    // --------- OWNER FUNCTIONS ---------
    function setDiscountManagerAddress(address _adr) external onlyOwner {
        discountManagerAddress = _adr;
    }

    // 0 - 10000
    function setPlatformFee(uint256 _fee) external onlyOwner {
        platformFee = _fee;
    }

    // 0 - 10000
    function setDailyInterest(uint256 _min, uint256 _max) external onlyOwner {
        minDailyInterest = _min;
        maxDailyInterest = _max;
    }

    function setNFTShipperAddress(address _shipper) external onlyOwner {
        nftShipperAddress = _shipper;
    }

    function setPaymentReceiver(address _paymentReceiver) external onlyOwner {
        paymentReceiver = _paymentReceiver;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        IWAVAX(wavaxAddress).deposit{value: balance}();
        IERC20 wavax = IERC20(wavaxAddress);
        wavax.safeTransferFrom(address(this), paymentReceiver, balance);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
    // --------- OWNER FUNCTIONS ---------

    function acceptDeal(DataTypes.Listing calldata listing) external nonReentrant whenNotPaused payable {
        validateListingAndRevert(listing);

        address transferFromAddress = msg.sender;
        if (msg.value > 0) {
            if (msg.value < listing.askPrice) {
                revert InsufficientPayment();
            }
            // Convert paid avax to wavax and transfer from contract
            IWAVAX(wavaxAddress).deposit{value: listing.askPrice}();
            transferFromAddress = address(this);
        }
        nonceExecutedOrCancelled[listing.maker][listing.nonce] = 1;

        INFTShipper(nftShipperAddress)
            .transferNFT(listing.collection, listing.maker, address(this), listing.tokenId, listing.amount);
        createDeal(listing.collection, listing.tokenId, listing.amount,
            listing.maxLockTime, listing.maker, msg.sender, listing.askPrice, listing.dailyInterest);
        transferDealFunds(listing.collection, listing.maker, listing.askPrice, transferFromAddress);
    }

    function acceptMultipleDeals(DataTypes.Listing[] calldata listings) external nonReentrant whenNotPaused payable {
        address transferFromAddress = msg.sender;
        if (msg.value > 0) {
            uint256 totalPrice = 0;
            for (uint256 i = 0; i < listings.length; i += 1) {
                totalPrice += listings[i].askPrice;
            }
            if (msg.value < totalPrice) {
                revert InsufficientPayment();
            }
            IWAVAX(wavaxAddress).deposit{value: totalPrice}();
            transferFromAddress = address(this);
        }
        for (uint256 i = 0; i < listings.length; i += 1) {
            DataTypes.Listing calldata listing = listings[i];
            validateListingAndRevert(listing);
            nonceExecutedOrCancelled[listing.maker][listing.nonce] = 1;
            createDeal(listing.collection, listing.tokenId, listing.amount,
                listing.maxLockTime, listing.maker, msg.sender, listing.askPrice, listing.dailyInterest);
            transferDealFunds(listing.collection, listing.maker, listing.askPrice, transferFromAddress);
            INFTShipper(nftShipperAddress)
                .transferNFT(listing.collection, listing.maker, address(this), listing.tokenId, listing.amount);
        }
    }

    function acceptOffer(DataTypes.Offer calldata offer, uint256 tokenId) external nonReentrant whenNotPaused {
        // Override tokenId if offer is not a collection offer
        if (!offer.collectionOffer) {
            tokenId = offer.tokenId;
        }
        if (!isOwnerValid(msg.sender, offer.collection, tokenId, offer.amount)) {
            revert Unauthorized();
        }
        validateOfferAndRevert(offer);
        nonceExecutedOrCancelled[offer.taker][offer.nonce] = 1;
        INFTShipper(nftShipperAddress)
            .transferNFT(offer.collection, msg.sender, address(this), tokenId, offer.amount);
        createDeal(offer.collection, tokenId, offer.amount,
            offer.maxLockTime, msg.sender, offer.taker, offer.bidPrice, offer.dailyInterest);
        transferDealFunds(offer.collection, msg.sender, offer.bidPrice, offer.taker);
    }

    function createDeal(address collection, uint256 tokenId, uint256 amount, uint256 maxLockTime,
        address maker, address taker, uint256 dealPrice, uint256 dailyInterest) internal {
        uint256 expiresAt;
        unchecked {
            expiresAt = maxLockTime + block.timestamp;
        }
        idToDeal[nextDealId] = DataTypes.Deal({
            dealId: nextDealId,
            maker: maker,
            taker: taker,
            collection: collection,
            tokenId: tokenId,
            amount: amount,
            dealPrice: dealPrice,
            acceptedTs: block.timestamp,
            expiresTs: expiresAt,
            dailyInterest: dailyInterest,
            closed: false
        });
        emit NewDeal(idToDeal[nextDealId]);
        unchecked {
            nextDealId++;
        }
    }

    function transferDealFunds(address collection, address maker, uint256 dealPrice, address transferFundsFrom) internal {
        uint256 makerReceived = dealPrice - calculatePlatformFee(dealPrice, collection, maker);
        uint256 platformReceived = dealPrice - makerReceived;
        IERC20 wavax = IERC20(wavaxAddress);
        wavax.safeTransferFrom(transferFundsFrom, maker, makerReceived);
        wavax.safeTransferFrom(transferFundsFrom, paymentReceiver, platformReceived);
    }

    function getCloseNowPrice(uint256 dealId) external view returns(uint256) {
        DataTypes.Deal memory deal = idToDeal[dealId];
        if (deal.acceptedTs == 0 || deal.closed) {
            return 0;
        }
        if (deal.expiresTs < block.timestamp) {
            return 0;
        }
        uint256 interest = calculateInterest(deal.dealPrice, block.timestamp - deal.acceptedTs, deal.dailyInterest);
        return deal.dealPrice + interest;
    }

    function closeDeal(uint256 dealId) external nonReentrant whenNotPaused payable {
        DataTypes.Deal storage deal = idToDeal[dealId];
        if (deal.acceptedTs == 0 || deal.closed) {
            revert InvalidDeal();
        }
        // Expired. We don't care who sent the transaction
        if (deal.expiresTs < block.timestamp) {
            deal.closed = true;
            transferNFTFromContract(deal.collection, deal.tokenId, deal.amount, deal.taker);
        } else {
            // Payment
            if (msg.sender != deal.maker) {
                revert Unauthorized();
            }
            deal.closed = true;
            uint256 interest = calculateInterest(deal.dealPrice, block.timestamp - deal.acceptedTs, deal.dailyInterest);
            uint256 totalPayment = deal.dealPrice + interest;

            address transferFromAddress = msg.sender;
            if (msg.value > 0) {
                if (msg.value < totalPayment) {
                    revert InsufficientPayment();
                }
                IWAVAX(wavaxAddress).deposit{value: totalPayment}();
                transferFromAddress = address(this);
            }
            IERC20(wavaxAddress).safeTransferFrom(address(this), deal.taker, totalPayment);
            transferNFTFromContract(deal.collection, deal.tokenId, deal.amount, deal.maker);
        }
        emit DealClosed(deal);
    }

    function forceCloseDeal(uint256 dealId) external nonReentrant onlyOwner {
        DataTypes.Deal storage deal = idToDeal[dealId];
        if (deal.acceptedTs == 0 || deal.closed) {
            revert InvalidDeal();
        }
        deal.closed = true;
        transferNFTFromContract(deal.collection, deal.tokenId, deal.amount, deal.taker);
        emit DealClosed(deal);
    }

    function isOwnerValid(address owner, address collection, uint256 tokenId, uint256 amount) internal returns(bool) {
        ITokenIdentifier identifier = ITokenIdentifier(nftShipperAddress);
        if (identifier.isERC721(collection)) {
            return IERC721(collection).ownerOf(tokenId) == owner;
        } else if (identifier.isERC1155(collection)) {
            return IERC1155(collection).balanceOf(owner, tokenId) >= amount;
        }
        return false;
    }

    function transferNFTFromContract(address collection, uint256 tokenId, uint256 amount, address to) internal {
        ITokenIdentifier identifier = ITokenIdentifier(nftShipperAddress);
        if (identifier.isERC721(collection)) {
            IERC721(collection).safeTransferFrom(address(this), to, tokenId);
        } else if (identifier.isERC1155(collection)) {
            IERC1155(collection).safeTransferFrom(address(this), to, tokenId, amount, "");
        } else {
            // Should never come to here since we are using the same logic while transferring token to contract
            revert UnsupportedTokenType();
        }
    }

    function validateListingAndRevert(DataTypes.Listing calldata listing) public view {
        if (listing.dailyInterest < minDailyInterest || listing.dailyInterest > maxDailyInterest) {
            revert OutOfBounds();
        }
        if (!verifyListing(listing)) {
            revert InvalidSignature();
        }
        if (listing.expiresAt < block.timestamp || listing.nonce < userMinNonce[listing.maker] || nonceExecutedOrCancelled[listing.maker][listing.nonce] == 1) {
            revert OrderExpired();
        }
    }

    function validateOfferAndRevert(DataTypes.Offer calldata offer) public view {
        if (offer.dailyInterest < minDailyInterest || offer.dailyInterest > maxDailyInterest) {
            revert OutOfBounds();
        }
        if (!verifyOffer(offer)) {
            revert InvalidSignature();
        }
        if (offer.expiresAt < block.timestamp || offer.nonce < userMinNonce[offer.taker] || nonceExecutedOrCancelled[offer.taker][offer.nonce] == 1) {
            revert OrderExpired();
        }
    }

    function cancelAllOrdersAndOffers(uint256 minNonce) external nonReentrant whenNotPaused {
        if (minNonce < userMinNonce[msg.sender] || minNonce > userMinNonce[msg.sender] + 500000) {
            revert OutOfBounds();
        }
        userMinNonce[msg.sender] = minNonce;
        emit CancelAllOrdersAndOffers(msg.sender, minNonce);
    }

    function cancelMultipleOrdersAndOffers(uint256[] calldata nonceList) external nonReentrant whenNotPaused {
        if (nonceList.length == 0) {
            return;
        }
        for (uint256 i = 0; i < nonceList.length; i += 1) {
            if (nonceList[i] < userMinNonce[msg.sender]) {
                revert OutOfBounds();
            }
            nonceExecutedOrCancelled[msg.sender][nonceList[i]] = 1;
        }
        emit CancelMultipleOrdersAndOffers(msg.sender, nonceList);
    }

    function calculateInterest(uint256 dealAmount, uint256 passedTime, uint256 dailyInterest) internal pure returns (uint256) {
        uint256 totalDays = passedTime / 86400;
        uint256 expectedTotalTime = totalDays * 86400;
        if (passedTime > expectedTotalTime) {
            totalDays++;
        }
        return dealAmount * (dailyInterest * totalDays) / (100 * percentageMultiplier);
    }

    function calculatePlatformFee(uint256 price, address collection, address maker) public view returns (uint256) {
        uint256 fee = price * platformFee / (100 * percentageMultiplier);
        // No discount
        if (discountManagerAddress == address(0)) {
            return fee;
        }
        uint256 discountRate = IDiscountManager(discountManagerAddress).getDiscountRate(collection, maker);
        if (discountRate == 0) {
            return fee;
        }
        return fee - ((fee * discountRate) / (100 * percentageMultiplier));
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {DataTypes} from "./libraries/DataTypes.sol";

contract SignatureVerifier {
    using DataTypes for DataTypes.Listing;
    using DataTypes for DataTypes.Offer;

    bytes32 public domainSeparator;

    constructor() {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId)"),
                keccak256("PawnPeer"),
                keccak256(bytes("1")),
                block.chainid
            )
        );
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Signature: Invalid s parameter");
        require(v == 27 || v == 28, "Signature: Invalid v parameter");
        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");
        return signer;
    }

    function verifyLowLevel(bytes32 hash, address signer, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return IERC1271(signer)
            .isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }

    function verifyListing(DataTypes.Listing calldata listing) public view returns (bool) {
        bytes32 hash = listing.hashListing();
        return verifyLowLevel(hash, listing.maker, listing.v, listing.r, listing.s);
    }

    function verifyOffer(DataTypes.Offer calldata offer) public view returns (bool) {
        bytes32 hash = offer.hashOffer();
        return verifyLowLevel(hash, offer.taker, offer.v, offer.r, offer.s);
    }
}