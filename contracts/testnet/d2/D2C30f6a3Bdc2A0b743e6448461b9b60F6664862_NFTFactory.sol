// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/internal/Cloner.sol";
import "oz-custom/contracts/internal/FundForwarder.sol";
import "oz-custom/contracts/internal/MultiDelegatecall.sol";

import "./internal/Base.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/ICollectible721.sol";

contract NFTFactory is Base, Cloner, FundForwarder, MultiDelegatecall {
    /// @dev value is equal to keccak256("CollectibleCloner_v1")
    bytes32 public constant VERSION =
        0xa8c6a324d9e999a7a85f4a5b54b78927575d1be8226ddaf15e1dbd2dc8fdaec7;

    constructor(
        address implement_,
        IAuthority authority_,
        ITreasury vault_
    )
        payable
        Cloner(implement_)
        FundForwarder(address(vault_))
        Base(authority_, Roles.FACTORY_ROLE)
    {}

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory) {
        return _multiDelegatecall(data_);
    }

    function setImplement(
        address implement_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit ImplementChanged(implement(), implement_);
        _setImplement(implement_);
    }

    function clone(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata baseExtension_,
        uint256 mintPrice_,
        uint256 chainIdentifier_
    ) external returns (address) {
        // get rid of stack too deep
        _checkRole(Roles.OPERATOR_ROLE, _msgSender());
        return
            _clone(
                __saltOf(name_, symbol_),
                ICollectible721.init.selector,
                abi.encode(
                    authority(),
                    vault,
                    name_,
                    symbol_,
                    baseURI_,
                    baseExtension_,
                    mintPrice_,
                    chainIdentifier_
                )
            );
    }

    function cloneOf(
        string calldata name_,
        string calldata symbol_
    ) external view returns (address, bool) {
        bytes32 salt = keccak256(
            abi.encodePacked(name_, symbol_, address(this), VERSION)
        );
        return _cloneOf(salt);
    }

    function __saltOf(
        string calldata name_,
        string calldata symbol_
    ) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(name_, symbol_, address(this), VERSION));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/interfaces/IBlacklistableUpgradeable.sol";

interface IAuthority is
    IBlacklistableUpgradeable,
    IAccessControlEnumerableUpgradeable
{
    event ProxyAccessGranted(address indexed proxy);

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool isPaused);

    function requestAccess(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ITreasury.sol";
import "./IAuthority.sol";

interface ICollectible721 {
    error Collectible721__InsufficientAmount();
    error Collectible721__UnsupportedPayments();

    function init(
        IAuthority authority_,
        ITreasury treasury_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata baseExtension_,
        uint256 mintPrice_,
        uint256 chainIdentifier_
    ) external;

    function recoverNFTs() external;

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory);

    function mint(
        address to_,
        string calldata tokenURI_
    ) external returns (uint256);

    function mint(
        string calldata tokenURI_,
        address to_,
        address paymentToken_,
        uint256 value_
    ) external returns (uint256);

    function mintBatch(
        address to_,
        string[] calldata tokenURIs_
    ) external returns (uint256[] memory);

    function mintBatch(
        string[] calldata tokenURIs_,
        address to_,
        address paymentToken_,
        uint256 value_
    ) external returns (uint256[] memory);

    function setBaseURI(string calldata baseURI_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/interfaces/IWithdrawableUpgradeable.sol";

interface ITreasury {
    error Treasury__Expired();
    error Treasury__LengthMismatch();
    error Treasury__InvalidSignature();

    event PaymentsUpdated(address[] indexed tokens);
    event PricesUpdated(address[] indexed tokens, uint256[] indexed prices);
    event PriceUpdated(
        IERC20Upgradeable indexed token,
        uint256 indexed from,
        uint256 indexed to
    );
    event PaymentRemoved(address indexed token);
    event PaymentsRemoved();

    function supportedPayment(address token_) external view returns (bool);

    function priceOf(address token_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../interfaces/IAuthority.sol";

import "../libraries/Roles.sol";

error Base__Paused();
error Base__NotPaused();
error Base__AlreadySet();
error Base__Blacklisted();
error Base__Unauthorized();

abstract contract Base {
    bytes32 private _authority;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    modifier onlyWhitelisted() {
        _checkBlacklist(msg.sender);
        _;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    event AuthorityUpdated(IAuthority indexed from, IAuthority indexed to);

    constructor(IAuthority authority_, bytes32 role_) payable {
        authority_.requestAccess(role_);
        __updateAuthority(authority_);
    }

    function updateAuthority(
        IAuthority authority_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        IAuthority old = authority();
        if (old == authority_) revert Base__AlreadySet();
        __updateAuthority(authority_);
        emit AuthorityUpdated(old, authority_);
    }

    function authority() public view returns (IAuthority authority_) {
        /// @solidity memory-safe-assembly
        assembly {
            authority_ := sload(_authority.slot)
        }
    }

    function _checkBlacklist(address account_) internal view {
        if (authority().isBlacklisted(account_)) revert Base__Blacklisted();
    }

    function _checkRole(bytes32 role_, address account_) internal view {
        if (!authority().hasRole(role_, account_)) revert Base__Unauthorized();
    }

    function __updateAuthority(IAuthority authority_) internal {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_authority.slot, authority_)
        }
    }

    function _requirePaused() internal view {
        if (!authority().paused()) revert Base__NotPaused();
    }

    function _requireNotPaused() internal view {
        if (authority().paused()) revert Base__Paused();
    }

    function _hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool) {
        return authority().hasRole(role_, account_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Roles {
    bytes32 public constant PROXY_ROLE =
        0x77d72916e966418e6dc58a19999ae9934bef3f749f1547cde0a86e809f19c89b;
    bytes32 public constant SIGNER_ROLE =
        0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    bytes32 public constant TREASURER_ROLE =
        0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07;
    bytes32 public constant FACTORY_ROLE =
        0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBlacklistableUpgradeable {
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);

    function setUserStatus(address account_, bool status) external;

    function isBlacklisted(address account_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWithdrawableUpgradeable {
    event Withdrawn(
        address indexed token,
        address indexed to,
        uint256 indexed value
    );
    event Received(address indexed sender, uint256 indexed value);

    function withdraw(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ICloner.sol";

import "../oz/proxy/Clones.sol";

import "../libraries/Bytes32Address.sol";

abstract contract Cloner is ICloner {
    using Clones for address;
    using Bytes32Address for bytes32;
    using Bytes32Address for address;

    bytes32 private __implement;
    mapping(bytes32 => address[]) private __clones;

    constructor(address implement_) payable {
        _setImplement(implement_);
    }

    function setImplement(address implement_) external virtual;

    function implement() public view returns (address) {
        return __implement.fromFirst20Bytes();
    }

    function _cloneOf(bytes32 salt_)
        internal
        view
        returns (address clone, bool isCloned)
    {
        clone = implement().predictDeterministicAddress(salt_);
        isCloned = clone.code.length != 0;
    }

    function allClonesOf(address implement_)
        external
        view
        returns (address[] memory clones)
    {
        return __clones[implement_.fillLast12Bytes()];
    }

    function _setImplement(address implement_) internal {
        __implement = implement_.fillLast12Bytes();
    }

    function _clone(
        bytes32 salt_,
        bytes4 initSelector_,
        bytes memory initCode_
    ) internal returns (address clone) {
        address _implement = implement();
        clone = _implement.cloneDeterministic(salt_);
        (bool ok, ) = clone.call(abi.encodePacked(initSelector_, initCode_));
        if (!ok) revert Cloner__InitCloneFailed();

        __clones[_implement.fillLast12Bytes()].push(clone);

        emit Cloned(_implement, clone, salt_, clone.codehash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Context.sol";

import "./Transferable.sol";

error FundForwarder__ForwardFailed();

abstract contract FundForwarder is Context, Transferable {
    address public vault;

    event VaultUpdated(address indexed from, address indexed to);
    event Forwarded(address indexed from, uint256 indexed amount);

    constructor(address vault_) payable {
        _changeVault(vault_);
    }

    receive() external payable virtual {
        (bool ok, ) = vault.call{value: msg.value}("");
        if (!ok) revert FundForwarder__ForwardFailed();
        emit Forwarded(_msgSender(), msg.value);
    }

    function recoverERC20(IERC20 token_, uint256 amount_) external {
        _safeERC20Transfer(token_, vault, amount_);
    }

    function recoverNative() external {
        _safeNativeTransfer(vault, address(this).balance);
    }

    function _changeVault(address vault_) internal {
        emit VaultUpdated(vault, vault_);
        vault = vault_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICloner {
    error Cloner__InitCloneFailed();

    event Cloned(
        address indexed implement,
        address indexed clone,
        bytes32 indexed salt,
        bytes32 bytecodeHash
    );

    event ImplementChanged(address indexed from, address indexed to);

    function setImplement(address implement_) external;

    function implement() external view returns (address);

    function allClonesOf(address implement_)
        external
        view
        returns (address[] memory clones);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error MultiDelegatecall__OnlyDelegate();
error MultiDelegatecall__ExecutionFailed();

abstract contract MultiDelegatecall {
    address public immutable original;

    constructor() payable {
        original = address(this);
    }

    function _multiDelegatecall(bytes[] calldata data_)
        internal
        returns (bytes[] memory results)
    {
        if (address(this) != original) revert MultiDelegatecall__OnlyDelegate();
        uint256 length = data_.length;
        results = new bytes[](length);
        bool ok;
        for (uint256 i; i < length; ) {
            (ok, results[i]) = address(this).delegatecall(data_[i]);
            if (!ok) revert MultiDelegatecall__ExecutionFailed();
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/token/ERC20/IERC20.sol";

error Transferable__TransferFailed();
error Transferable__InvalidArguments();

abstract contract Transferable {
    function _safeTransferFrom(
        IERC20 token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual {
        __checkValidTransfer(to_, value_);
        bool success;
        if (address(token_) == address(0))
            success = __nativeTransfer(to_, value_);
        else success = __ERC20TransferFrom(token_, from_, to_, value_);

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeTransfer(
        IERC20 token_,
        address to_,
        uint256 value_
    ) internal virtual {
        __checkValidTransfer(to_, value_);
        bool success;
        if (address(token_) == address(0))
            success = __nativeTransfer(to_, value_);
        else success = __ERC20Transfer(token_, to_, value_);

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeNativeTransfer(address to_, uint256 amount_)
        internal
        virtual
    {
        __checkValidTransfer(to_, amount_);
        if (!__nativeTransfer(to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20Transfer(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);
        if (!__ERC20Transfer(token_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20TransferFrom(
        IERC20 token_,
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);

        if (!__ERC20TransferFrom(token_, from_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function __nativeTransfer(address to_, uint256 amount_)
        private
        returns (bool success)
    {
        assembly {
            success := call(gas(), to_, amount_, 0, 0, 0, 0)
        }
    }

    function __ERC20Transfer(
        IERC20 token_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to_) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), value_) // Append the "amount" argument.

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
    }

    function __ERC20TransferFrom(
        IERC20 token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            let freeMemoryPointer := mload(0x40)

            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from_)
            mstore(add(freeMemoryPointer, 36), to_)
            mstore(add(freeMemoryPointer, 68), value_)

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 100, 0, 32)
            )
        }
    }

    function __checkValidTransfer(address to_, uint256 value_) private pure {
        if (value_ == 0 || to_ == address(0))
            revert Transferable__InvalidArguments();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getAllRoleMembers(bytes32 role_)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    error AccessControl__Unauthorized();
    error AccessControl__RoleMissing(bytes32 role, address account);
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    error ERC20__Expired();
    error ERC20__StringTooLong();
    error ERC20__InvalidSignature();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error ERC20__Expired();
    error ERC20__StringTooLong();
    error ERC20__InvalidSignature();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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