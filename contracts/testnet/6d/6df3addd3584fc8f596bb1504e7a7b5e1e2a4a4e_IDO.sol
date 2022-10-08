/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-08
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

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
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: ido.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
//.................Created BY Umair Riaz...................//






interface IPool {

  struct PoolModel {
    uint256 hardCap; // how much project wants to raise
    uint256 softCap; // how much of the raise will be accepted as successful IDO
    uint256 startDateTime;
    uint256 endDateTime;
    PoolStatus status; //: by default “Upcoming”,
  }


  struct IDOInfo {
    address projectTokenAddress; //the address of the token that project is offering in return
    uint16 minAllocationPerUser;
    uint256 maxAllocationPerUser;
    uint256 tokenPrice;
    uint256 totalTokenSold;
  }


  struct CompletePoolDetails {
    PoolModel pool;
    IDOInfo poolDetails;
    uint256 totalRaised;
  }

   struct ParticipantDetails {
     address participantsAddress;
    string Type_of_Currency;
    uint256 amount;
    bool Fund_Released;
  }

  enum PoolStatus {
    Upcoming,
    Ongoing,
    Finished,
    Paused,
    Cancelled
  }

    enum TypeOfFund{
    Ether,
    BNB,
    USDT,
    BUSD
  }



  function addIDOInfo(IDOInfo memory _detailedPoolInfo) external;
  function getCompletePoolDetails() external view returns (CompletePoolDetails memory poolDetails);
  function  Get_Participants() external view returns(ParticipantDetails[] memory);
  function updatePoolStatus(uint256 _newStatus) external;
   function claimedTokens(address _address) external  returns (uint tokenanount);
  function Deposite (address _sender, uint amount,  TypeOfFund tokentype ) external payable ;
}









//.................Created BY Umair Riaz...................//

contract Pool is IPool, Ownable {
  PoolModel private poolInformation;
  IDOInfo private idoInfo;
  AggregatorV3Interface internal priceFeed;
  uint256 private TotalRaised;  
  mapping (uint => ParticipantDetails) private  Parcipations;
  uint public  Total_Participants;
  mapping (uint => IPool.CompletePoolDetails) private PoolList;
  mapping (address => uint) private StoreAddres;


  event LogPoolContractAddress(address);
  event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
  event LogDeposit(address indexed participant, uint256 amount);

  constructor(PoolModel memory _pool) {
        require(_pool.hardCap > 0, "hardCap must  > 0");
        require(_pool.softCap > 0, "softCap must  > 0");
        require(_pool.softCap < _pool.hardCap, "softCap must < hardCap");
        require(_pool.startDateTime > block.timestamp,"startDateTime must  > now");
        require( _pool.endDateTime > block.timestamp,"endDate must be at future time");
    poolInformation = IPool.PoolModel({
      hardCap: _pool.hardCap,
      softCap: _pool.softCap,
      startDateTime: _pool.startDateTime,
      endDateTime: _pool.endDateTime,
      status: _pool.status
    });
    // priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    // priceFeeds = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d); // for token DAI
    emit LogPoolContractAddress(address(this));
  }


  function addIDOInfo(IDOInfo memory _pdi) external override onlyOwner {
    require( address(idoInfo.projectTokenAddress) == address(0), "already added IDO info");
    _preIDOInfoUpdate(_pdi);
    idoInfo.projectTokenAddress = _pdi.projectTokenAddress;
    idoInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
    idoInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    idoInfo.tokenPrice = _pdi.tokenPrice;
    idoInfo.totalTokenSold = _pdi.totalTokenSold;
  }

  function _preIDOInfoUpdate(IDOInfo memory _idoInfo) private pure {
    require(_idoInfo.minAllocationPerUser > 0, "minAllocation must > 0");
    require( _idoInfo.minAllocationPerUser < _idoInfo.maxAllocationPerUser, "minAllocation must < max");
    require(_idoInfo.tokenPrice > 0, "price must  > 0");
  }



  receive() external payable {
  }


function Deposite (address _sender, uint amount,   TypeOfFund tokentype ) external payable override {
    
    if (tokentype == TypeOfFund.Ether){
               //         (
    //         /*uint80 roundID*/,
    //          int price,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //         ) = priceFeed.latestRoundData();
    //  uint Price_in_USD   = uint(price) * amount; // Current Price of USD Multiply by total ether 
     Parcipations[Total_Participants].participantsAddress = _sender;
      Parcipations[Total_Participants].Type_of_Currency = "Ether";
     Parcipations[Total_Participants].amount = amount;
     Parcipations[Total_Participants].Fund_Released = false;
     StoreAddres[_sender] = Total_Participants;
     Total_Participants ++ ;
     TotalRaised +=  amount;
     emit LogDeposit(_sender,  amount);
    //  }else if(TypeOfFund(tokentype) == TypeOfFund.BNB){
    //                         //         (
    // //         /*uint80 roundID*/,
    // //          int price,
    // //         /*uint startedAt*/,
    // //         /*uint timeStamp*/,
    // //         /*uint80 answeredInRound*/
    // //         ) = priceFeed.latestRoundData();
    // //  uint Price_in_USD   = uint(price) * amount; // Current Price of USD Multiply by total ether 
    //  Parcipations[Total_Participants].participantsAddress = _sender;
    //   Parcipations[Total_Participants].Type_of_Currency = "BNB";
    //  Parcipations[Total_Participants].amount = amount;
    //  Parcipations[Total_Participants].Fund_Released = false;
    //  StoreAddres[_sender] = Total_Participants;
    //  Total_Participants ++ ;
    //  TotalRaised +=  amount;
    //  emit LogDeposit(_sender,  amount);
    //  }else if(TypeOfFund(tokentype) == TypeOfFund.USDT){
    //                               //         (
    // //         /*uint80 roundID*/,
    // //          int price,
    // //         /*uint startedAt*/,
    // //         /*uint timeStamp*/,
    // //         /*uint80 answeredInRound*/
    // //         ) = priceFeed.latestRoundData();
    // //  uint Price_in_USD   = uint(price) * amount; // Current Price of USD Multiply by total ether 
    //  Parcipations[Total_Participants].participantsAddress = _sender;
    //   Parcipations[Total_Participants].Type_of_Currency = "USDT";
    //  Parcipations[Total_Participants].amount = amount;
    //  Parcipations[Total_Participants].Fund_Released = false;
    //  StoreAddres[_sender] = Total_Participants;
    //  Total_Participants ++ ;
    //  TotalRaised +=  amount;
    //  emit LogDeposit(_sender,  amount);
    //  }else if(TypeOfFund(tokentype) == TypeOfFund.BUSD){
    //                               //         (
    // //         /*uint80 roundID*/,
    // //          int price,
    // //         /*uint startedAt*/,
    // //         /*uint timeStamp*/,
    // //         /*uint80 answeredInRound*/
    // //         ) = priceFeed.latestRoundData();
    // //  uint Price_in_USD   = uint(price) * amount; // Current Price of USD Multiply by total ether 
    //  Parcipations[Total_Participants].participantsAddress = _sender;
    //   Parcipations[Total_Participants].Type_of_Currency = "BUSD";
    //  Parcipations[Total_Participants].amount = amount;
    //  Parcipations[Total_Participants].Fund_Released = false;
    //  StoreAddres[_sender] = Total_Participants;
    //  Total_Participants ++ ;
    //  TotalRaised +=  amount;
    //  emit LogDeposit(_sender,  amount);
     }
}




function Get_Participants() external override  view returns(ParticipantDetails[] memory){
                ParticipantDetails[] memory ProposalArray = new ParticipantDetails[](Total_Participants);
                for(uint i=0 ; i < Total_Participants ; i++){
                   ProposalArray[i] = Parcipations[i] ;
            }
        return ProposalArray;
    }

  function _didAlreadyParticipated(uint index) private view returns (bool isIt){
    isIt = Parcipations[index].amount > 0;
  }




  function claimedTokens(address _address) external override  onlyOwner _isPoolFinished(poolInformation) returns (uint tokenanount){
    uint index = StoreAddres[_address];
    if( keccak256(bytes(Parcipations[index].Type_of_Currency)) == keccak256(bytes("Ether")) ){
            uint TokenSend = Parcipations[index].amount * 10**18;
            tokenanount = TokenSend / idoInfo.tokenPrice;
             Parcipations[index].Fund_Released = true;
      // }else if(keccak256(abi.encodePacked(Parcipations[StoreAddres[_address]].Type_of_Currency)) == keccak256("BNB")){
      //   uint TokenSend = Parcipations[StoreAddres[_address]].amount / idoInfo.tokenPrice ;
      //   projectTokens.transfer(Parcipations[StoreAddres[_address]].participantsAddress , TokenSend);
      //   Parcipations[StoreAddres[_address]].Fund_Released = true;
      // }else if(keccak256(abi.encodePacked(Parcipations[StoreAddres[_address]].Type_of_Currency)) == keccak256("USDT")){
      //   uint TokenSend = Parcipations[StoreAddres[_address]].amount / idoInfo.tokenPrice ;
      //   projectTokens.transfer(Parcipations[StoreAddres[_address]].participantsAddress , TokenSend);
      //   Parcipations[StoreAddres[_address]].Fund_Released = true;
      }
  }


  function _getTotalRaised() private view returns (uint256 amount) {
    amount = TotalRaised;
  }


  function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
    require(_newStatus < 5 && _newStatus >= 0, "wrong Status;");
    uint256 currentStatus = uint256(poolInformation.status);
    poolInformation.status = PoolStatus(_newStatus);
    emit LogPoolStatusChanged(currentStatus, _newStatus);
  }


  function getCompletePoolDetails() external view override returns(CompletePoolDetails memory poolDetails){
     poolDetails = CompletePoolDetails({
      totalRaised: TotalRaised,
      pool: poolInformation,
      poolDetails: idoInfo
    });

  }



  modifier _pooIsOngoing(IPool.PoolModel storage _pool) {
    require(_pool.status == IPool.PoolStatus.Ongoing, "Pool not open!");
    require(_pool.startDateTime >= block.timestamp, "Pool not started");
    require(_pool.endDateTime >= block.timestamp, "pool endDate passed");
    _;
  }



  modifier _isPoolFinished(IPool.PoolModel storage _pool) {
    require( _pool.status == IPool.PoolStatus.Finished, "Pool status not Finished!");
    _;
  }

  modifier _hardCapNotPassed(uint256 _hardCap) {
    uint256 _beforeBalance = _getTotalRaised();
    uint256 sum = _getTotalRaised() + msg.value;
    require(sum <= _hardCap, "hardCap reached!");
    assert(sum > _beforeBalance);
    _;
  }
  
}
//.................Created BY Umair Riaz...................//






















contract IDO is  AccessControl, Ownable {
  mapping(address => bool) private _didRefund; // keep track of users who did refund project token.
  bytes32 private  constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
  IPool private pool;
  IERC20 private projectToken;
  address[] public PoolContractAddress;
  mapping(address => bool) private whitelistedAddressesMap;
  address[] private   whitelistedAddressesArray;
  mapping(address => string) private checkCurreny;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);
  event LogPoolOwnerRoleGranted(address indexed owner);
  event LogPoolOwnerRoleRevoked(address indexed owner);
  event LogPoolCreated(address indexed poolOwner);
  event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);
  event LogWithdraw(address indexed participant, uint256 amount);
 

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }


  // Admin grants PoolOwner role to some address;
  function grantPoolOwnerRole(address _address) external onlyOwner  returns (bool success){
    require(address(0) != address(_address), "zero address");
    grantRole(POOL_OWNER_ROLE, _address);
    success = true;
  }


  // Admin revokes PoolOwner role feom an address;
  function revokePoolOwnerRole(address _address) external  onlyOwner {
    revokeRole(POOL_OWNER_ROLE, _address);
  }

// _createPoolOnlyOnce
  function createPool( uint256 _hardCap, uint256 _softCap, uint256 _startDateTime, uint256 _endDateTime,uint256 _status) external payable onlyRole(POOL_OWNER_ROLE) returns (bool success){
    // require(address(pool) == address(0), "Pool already created!");
    IPool.PoolModel memory model = IPool.PoolModel({
      hardCap: _hardCap,
      softCap: _softCap,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      status: IPool.PoolStatus(_status)
    });

    pool = new Pool(model);
    PoolContractAddress.push(address(pool));
    emit LogPoolCreated(_msgSender());
    success = true;
  }



// Add POOL INFORMATION
  function addIDOInfo(
    address _projectTokenAddress,
    uint16 _minAllocationPerUser,
    uint256 _maxAllocationPerUser,
    uint256 _tokenPrice,
    uint256 _totalTokenSold
  ) external onlyRole(POOL_OWNER_ROLE) {
    projectToken = IERC20(_projectTokenAddress);
    pool.addIDOInfo(
      IPool.IDOInfo({
        projectTokenAddress: _projectTokenAddress,
        minAllocationPerUser: _minAllocationPerUser,
        maxAllocationPerUser: _maxAllocationPerUser,
        tokenPrice: _tokenPrice,
        totalTokenSold: _totalTokenSold
      })
    );
  }



// Print Pool Address
  function poolsAddress() external  onlyRole(POOL_OWNER_ROLE) view returns (address[] memory){
     return PoolContractAddress;
  }

// Print the POOL Address
  function Get_pool_Balance() external  onlyRole(POOL_OWNER_ROLE) view returns (uint){
     return address(pool).balance;
  }


// update the POOL Status 
  function updatePoolStatus(uint256 newStatus) external onlyRole(POOL_OWNER_ROLE) returns (bool success){
    pool.updatePoolStatus(newStatus);
    emit LogPoolStatusChanged(_msgSender(), newStatus);
    success = true;
  }


// Print the POOL Complete Details
  function getCompletePoolDetails() external  view returns (IPool.CompletePoolDetails memory poolDetails){
     require(address(pool) != address(0), "No Pool!");
    poolDetails = pool.getCompletePoolDetails();
  }


// Print the POOL Participants List
  function Get_ParticipantsList() external view returns(IPool.ParticipantDetails[] memory){
        return pool.Get_Participants();
  }



  // whitelisted Functions
  function addAddressToWhitelist(address _address)  external onlyRole(POOL_OWNER_ROLE){
    require(address(0) != address(_address), "zero address");
    require(whitelistedAddressesMap[_address] == false,"Aleardy Listen");
    whitelistedAddressesMap[_address] = true;
    whitelistedAddressesArray.push(_address);
    emit AddedToWhitelist(_address);
  }

  function isWhitelisted(address _address) internal view  returns (bool isIt){
    isIt = whitelistedAddressesMap[_address];
  }
 

 // Fund transfer function
bool public_sale = false;

function Enable_Public_Sale() public onlyOwner {
      require(public_sale == false);
      public_sale = true;
    }

receive() external payable {}
function SEND_Fund(IPool.TypeOfFund  Type_token) external payable {
  if(whitelistedAddressesMap[msg.sender] == true){
   if (Type_token == IPool.TypeOfFund.Ether){
    checkCurreny[msg.sender] = "Ether";
    payable(address(this)).transfer(msg.value);
    uint ethvalue = msg.value;
    pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.BNB){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.USDT){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.BUSD){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
   }
  }else if (public_sale = false){
       if (Type_token == IPool.TypeOfFund.Ether){
    checkCurreny[msg.sender] = "Ether";
    payable(address(this)).transfer(msg.value);
    uint ethvalue = msg.value;
    pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.BNB){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.USDT){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
  //  }else if (Type_token == IPool.TypeOfFund.BUSD){
    // checkCurreny[msg.sender] = "Ether";
  //   payable(address(this)).transfer(msg.value);
  //   uint ethvalue = msg.value;
  //   pool.Deposite (msg.sender, ethvalue, Type_token);
   }
  }
}


// user can claim the token
function Claim() public  {
  require(whitelistedAddressesMap[msg.sender] == true,"Not Listed");
  require(!_didRefund[msg.sender], "Already claimed!");
   address reciver = msg.sender;
   uint amount = pool.claimedTokens(reciver);
   bool success = projectToken.transfer(reciver, amount);
  require(success, "Token transfer failed!");
  emit LogWithdraw(reciver, amount);
  
}

// user prarticipant can check the balance 
function balances(address _address) external  view returns(uint) {
  return projectToken.balanceOf(_address);      
}

// Address of IDO balance in Ethe
function balance() external view returns(uint){
  return address(this).balance;
}

// withdrwa the amount from the IDO contract participants
 function Withdraw( uint _amount) external returns(bool){
        require(_amount > 0 ,"need amount");
        if ( keccak256(bytes(checkCurreny[msg.sender])) == keccak256(bytes("Ether"))){
        uint amout = _amount * 10**18;
        payable(address(msg.sender)).transfer(amout);
        }
        //....
        //...
        //...
        return true;
    }


// owner of IDO can withdraw the amount 
 function WithdrawEther( address _address, uint _amount) external onlyOwner returns(bool){
        require(_amount > 0 ,"need amount");
        uint amout = _amount * 10**18;
         payable(address(_address)).transfer(amout);
        return true;
        }
}
//.................Created BY Umair Riaz...................//