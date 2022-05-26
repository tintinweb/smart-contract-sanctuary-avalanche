// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "lossless/contracts/utils/first-version/LERC20.sol";
import "../libraries/BasisPoints.sol";
import "../interfaces/ISparkWorldToken.sol";

contract SparkWorldToken is LERC20, AccessControl, ISparkWorldToken {
    using BasisPoints for uint256;

    string public constant NAME = "SparkWorld";
    string public constant SYMBOL = "SPRK";
    uint8 public constant DECIMALS = 18;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public constant INITIAL_SUPPLY =
        325000000 * (10**uint256(DECIMALS));

    address public SeedAddr;
    address public StrategicRoundAddr;
    address public PrivateSaleAddr;
    address public PublicSaleAddr;
    address public TeamAllocationAddr;
    address public StakingAddr;
    address public EchosystemTreasuryAddr;
    address public LiquidityAddr;
    address public AdvisorsAddr;
    address public AirdropAddr;

    address public feeWallet;

    uint256 public constant SEED = 19_500_000 * (10**uint256(DECIMALS)); // 6% for Seed
    uint256 public constant STRATEGIC_ROUND =
        26_000_000 * (10**uint256(DECIMALS)); // 8% for Strategic Round
    uint256 public constant PRIVATE_SALE = 26_000_000 * (10**uint256(DECIMALS)); // 8% for Private Sale
    uint256 public constant PUBLIC_SALE = 9_750_000 * (10**uint256(DECIMALS)); // 3% for Public Sale
    uint256 public constant TEAM_ALLOCATION =
        48_750_000 * (10**uint256(DECIMALS)); // 15% for Team Allocation
    uint256 public constant STAKING = 65_000_000 * (10**uint256(DECIMALS)); // 20% for Staking
    uint256 public constant ECHOSYSTEM_TREASURY =
        84_500_000 * (10**uint256(DECIMALS)); // 26% for Echosystem Treasury
    uint256 public constant LIQUIDITY = 19_500_000 * (10**uint256(DECIMALS)); // 6% for Liquidity
    uint256 public constant ADVISORS = 13_000_000 * (10**uint256(DECIMALS)); // 4% for Advisors
    uint256 public constant AIRDROP = 13_000_000 * (10**uint256(DECIMALS)); // 4% for Airdrop

    bool private _isDistributionComplete = false;

    /**
     * @param admin is the project owner’s administrative wallet address, this will be used
     *        in Lossless governance decision. It should be set to a wallet that we are
     *        planning on using to interact with Lossless protocol
     * @param recoveryAdmin project owner’s wallet that is used to change admin. We should
     *        use multisig for this and keep it as secure as possible as this wallet allows
     *        changing the admin wallet.
     * @param timelockPeriod timelock period in seconds dedicated for turning Lossless turn off.
     *        In case project decides to turn off Lossless they would have to wait for this
     *        period after initially proposing to turn the Lossless functionality off.
     *        Recommended timelockPeriod is 24 hours or 86400 seconds. Any lower timelockPeriod
     *        will be considered unsafe and will be marked as such in Lossless platform
     * @param lossless Lossless protocol controller address. Should be set to Lossless Controller
     *        address. Lossless Controller address is different on different chains. Any other
     *        address will not allow the token to function properly. Appropraite controller
     *        addresses can be found in
     *        https://lossless-cash.gitbook.io/lossless/technical-reference/lossless-controller/deployments
     * @param owner project owner’s wallet that is used to change operator in case of operator's
     *        private key exposure. This address's private key must not be on a server.
     */
    constructor(
        address admin,
        address recoveryAdmin,
        uint256 timelockPeriod,
        address lossless,
        address owner
    ) LERC20(0, NAME, SYMBOL, admin, recoveryAdmin, timelockPeriod, lossless) {
        _mint(address(this), INITIAL_SUPPLY);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(OPERATOR_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, owner);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OPERATOR_ROLE, OWNER_ROLE);
    }

    function getFeeWallet() external view returns (address) {
        return feeWallet;
    }

    function setFeeWallet(address _newFeeWallet)
        external
        onlyRole(OPERATOR_ROLE)
    {
        feeWallet = _newFeeWallet;
    }

    function setAllocationAddresses(
        address _SeedAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingAddr,
        address _EchosystemTreasuryAddr,
        address _LiquidityAddr,
        address _AdvisorsAddr,
        address _AirdropAddr
    ) public onlyRole(OPERATOR_ROLE) {
        require(!_isDistributionComplete);

        require(_SeedAddr != address(0));
        require(_StrategicRoundAddr != address(0));
        require(_PrivateSaleAddr != address(0));
        require(_PublicSaleAddr != address(0));
        require(_TeamAllocationAddr != address(0));
        require(_StakingAddr != address(0));
        require(_EchosystemTreasuryAddr != address(0));
        require(_LiquidityAddr != address(0));
        require(_AdvisorsAddr != address(0));
        require(_AirdropAddr != address(0));

        SeedAddr = _SeedAddr;
        StrategicRoundAddr = _StrategicRoundAddr;
        PrivateSaleAddr = _PrivateSaleAddr;
        PublicSaleAddr = _PublicSaleAddr;
        TeamAllocationAddr = _TeamAllocationAddr;
        StakingAddr = _StakingAddr;
        EchosystemTreasuryAddr = _EchosystemTreasuryAddr;
        LiquidityAddr = _LiquidityAddr;
        AdvisorsAddr = _AdvisorsAddr;
        AirdropAddr = _AirdropAddr;

        feeWallet = EchosystemTreasuryAddr;
    }

    function distributeTokens() public onlyRole(OPERATOR_ROLE) {
        require((!_isDistributionComplete));

        _transfer(address(this), SeedAddr, SEED);
        _transfer(address(this), StrategicRoundAddr, STRATEGIC_ROUND);
        _transfer(address(this), PrivateSaleAddr, PRIVATE_SALE);
        _transfer(address(this), PublicSaleAddr, PUBLIC_SALE);
        _transfer(address(this), TeamAllocationAddr, TEAM_ALLOCATION);
        _transfer(address(this), StakingAddr, STAKING);
        _transfer(address(this), EchosystemTreasuryAddr, ECHOSYSTEM_TREASURY);
        _transfer(address(this), LiquidityAddr, LIQUIDITY);
        _transfer(address(this), AdvisorsAddr, ADVISORS);
        _transfer(address(this), AirdropAddr, AIRDROP);

        _isDistributionComplete = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        _checkRole(role, _msgSender());
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "../../interfaces/ILosslessERC20.sol";
import "../../interfaces/ILosslessController.sol";

contract LERC20 is Context, ILERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address public recoveryAdmin;
    address private recoveryAdminCandidate;
    bytes32 private recoveryAdminKeyHash;
    address override public admin;
    uint256 public timelockPeriod;
    uint256 public losslessTurnOffTimestamp;
    bool public isLosslessOn = true;
    ILssController public lossless;

    constructor(uint256 totalSupply_, string memory name_, string memory symbol_, address admin_, address recoveryAdmin_, uint256 timelockPeriod_, address lossless_) {
        _mint(_msgSender(), totalSupply_);
        _name = name_;
        _symbol = symbol_;
        admin = admin_;
        recoveryAdmin = recoveryAdmin_;
        recoveryAdminCandidate = address(0);
        recoveryAdminKeyHash = "";
        timelockPeriod = timelockPeriod_;
        losslessTurnOffTimestamp = 0;
        lossless = ILssController(lossless_);
    }

    // --- LOSSLESS modifiers ---

    modifier lssAprove(address spender, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeApprove(_msgSender(), spender, amount);
        } 
        _;
    }

    modifier lssTransfer(address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransfer(_msgSender(), recipient, amount);
        } 
        _;
    }

    modifier lssTransferFrom(address sender, address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransferFrom(_msgSender(),sender, recipient, amount);
        }
        _;
    }

    modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
        if (isLosslessOn) {
            lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
        }
        _;
    }

    modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
        if (isLosslessOn) {
            lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
        }
        _;
    }

    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LERC20: Must be recovery admin");
        _;
    }

    // --- LOSSLESS management ---
    function transferOutBlacklistedFunds(address[] calldata from) override external {
        require(_msgSender() == address(lossless), "LERC20: Only lossless contract");

        uint256 fromLength = from.length;
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < fromLength; i++) {
            address fromAddress = from[i];
            uint256 fromBalance = _balances[fromAddress];
            _balances[fromAddress] = 0;
            totalAmount += fromBalance;
            emit Transfer(fromAddress, address(lossless), fromBalance);
        }

        _balances[address(lossless)] += totalAmount;
    }

    function setLosslessAdmin(address newAdmin) override external onlyRecoveryAdmin {
        require(newAdmin != admin, "LERC20: Cannot set same address");
        emit NewAdmin(newAdmin);
        admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) override  external onlyRecoveryAdmin {
        recoveryAdminCandidate = candidate;
        recoveryAdminKeyHash = keyHash;
        emit NewRecoveryAdminProposal(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) override external {
        require(_msgSender() == recoveryAdminCandidate, "LERC20: Must be canditate");
        require(keccak256(key) == recoveryAdminKeyHash, "LERC20: Invalid key");
        emit NewRecoveryAdmin(recoveryAdminCandidate);
        recoveryAdmin = recoveryAdminCandidate;
        recoveryAdminCandidate = address(0);
    }

    function proposeLosslessTurnOff() override external onlyRecoveryAdmin {
        require(losslessTurnOffTimestamp == 0, "LERC20: TurnOff already proposed");
        require(isLosslessOn, "LERC20: Lossless already off");
        losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
        emit LosslessTurnOffProposal(losslessTurnOffTimestamp);
    }

    function executeLosslessTurnOff() override external onlyRecoveryAdmin {
        require(losslessTurnOffTimestamp != 0, "LERC20: TurnOff not proposed");
        require(losslessTurnOffTimestamp <= block.timestamp, "LERC20: Time lock in progress");
        isLosslessOn = false;
        losslessTurnOffTimestamp = 0;
        emit LosslessOff();
    }

    function executeLosslessTurnOn() override external onlyRecoveryAdmin {
        require(!isLosslessOn, "LERC20: Lossless already on");
        losslessTurnOffTimestamp = 0;
        isLosslessOn = true;
        emit LosslessOn();
    }

    function getAdmin() override public view virtual returns (address) {
        return admin;
    }

    // --- ERC20 methods ---

    function name() override public view virtual returns (string memory) {
        return _name;
    }

    function symbol() override public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() override public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override lssTransfer(recipient, amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override lssAprove(spender, amount) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override lssTransferFrom(sender, recipient, amount) returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "LERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) override public virtual lssIncreaseAllowance(spender, addedValue) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) override public virtual lssDecreaseAllowance(spender, subtractedValue) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "LERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "LERC20: transfer from the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "LERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "LERC20: mint to the zero address");
    
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked { 
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

library BasisPoints {
    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return (amt * bp) / (BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return (amt * BASIS_POINTS) / (bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt + (mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt - (mulBP(amt, bp));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "lossless/contracts/interfaces/ILosslessERC20.sol";

interface ISparkWorldToken is ILERC20 {
    function setAllocationAddresses(
        address _SeedAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingAddr,
        address _EchosystemTreasuryAddr,
        address _LiquidityAddr,
        address _AdvisorsAddr,
        address _AirdropAddr
    ) external;

    function distributeTokens() external;

    function getFeeWallet() external returns (address);

    function setFeeWallet(address _newFeeWallet) external;
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
pragma solidity ^0.8.0;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./IProtectionStrategy.sol";

interface ILssController {
    // function getLockedAmount(ILERC20 _token, address _account)  returns (uint256);
    // function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) external returns(uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address _dexAddress) external returns (bool);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessGovernance() external view returns (ILssGovernance);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    function extraordinaryRetrievalProposalPeriod() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;
    function setPauseAdmin(address _newPauseAdmin) external;
    function setSettlementTimeLock(uint256 _newTimelock) external;
    function setDexTransferThreshold(uint256 _newThreshold) external;
    function setDexList(address[] calldata _dexList, bool _value) external;
    function setWhitelist(address[] calldata _addrList, bool _value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(ILssStaking _adr) external;
    function setReportingContractAddress(ILssReporting _adr) external; 
    function setGovernanceContractAddress(ILssGovernance _adr) external;
    function setTokenMintLimit(ILERC20 _token, uint256 limit) external;
    function setTokenMintPeriod(ILERC20 _token, uint256 _period) external;
    function setTokenBurnLimit(ILERC20 _token, uint256 _limit) external;
    function setTokenBurnPeriod(ILERC20 _token, uint256 _period) external;
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) external;
    function executeNewSettlementPeriod(ILERC20 _token) external;
    function activateEmergency(ILERC20 _token) external;
    function deactivateEmergency(ILERC20 _token) external;
    function setGuardian(address _newGuardian) external;
    function removeProtectedAddress(ILERC20 _token, address _protectedAddresss) external;
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function afterTransfer(address _sender, address _recipient, uint256 _amount) external;
    function setProtectedAddress(ILERC20 _token, address _protectedAddress, ProtectionStrategy _strategy) external;
    function setExtraordinaryRetrievalPeriod(uint256 _newPEriod) external;
    function extraordinaryRetrieval(ILERC20 _token, address[] calldata addresses, uint256 fundsToRetrieve) external;

    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
    event PauseAdminChange(address indexed _newAdmin);
    event GuardianSet(address indexed _oldGuardian, address indexed _newGuardian);
    event NewProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress, address indexed _strategy);
    event RemovedProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress);
    event NewSettlementPeriodProposal(ILERC20 indexed _token, uint256 _seconds);
    event SettlementPeriodChange(ILERC20 indexed _token, uint256 _proposedTokenLockTimeframe);
    event NewSettlementTimelock(uint256 indexed _timelock);
    event NewDexThreshold(uint256 indexed _newThreshold);
    event NewDex(address indexed _dexAddress);
    event DexRemoval(address indexed _dexAddress);
    event NewWhitelistedAddress(address indexed _whitelistAdr);
    event WhitelistedAddressRemoval(address indexed _whitelistAdr);
    event NewBlacklistedAddress(address indexed _blacklistedAddres);
    event AccountBlacklistRemoval(address indexed _adr);
    event NewStakingContract(ILssStaking indexed _newAdr);
    event NewReportingContract(ILssReporting indexed _newAdr);
    event NewGovernanceContract(ILssGovernance indexed _newAdr);
    event EmergencyActive(ILERC20 indexed _token);
    event EmergencyDeactivation(ILERC20 indexed _token);
    event NewMint(ILERC20 indexed token, address indexed account, uint256 indexed amount);
    event NewMintLimit(ILERC20 indexed token, uint256 indexed limit);
    event NewMintPeriod(ILERC20 indexed token, uint256 indexed period);
    event NewBurn(ILERC20 indexed token, address indexed account, uint256 indexed amount);
    event NewBurnLimit(ILERC20 indexed token, uint256 indexed limit);
    event NewBurnPeriod(ILERC20 indexed token, uint256 indexed period);
    event NewExtraordinaryPeriod(uint256 indexed extraordinaryRetrievalProposalPeriod);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssGovernance {
    function LSS_TEAM_INDEX() external view returns(uint256);
    function TOKEN_OWNER_INDEX() external view returns(uint256);
    function COMMITEE_INDEX() external view returns(uint256);
    function committeeMembersCount() external view returns(uint256);
    function walletDisputePeriod() external view returns(uint256);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessController() external view returns (ILssController);
    function isCommitteeMember(address _account) external view returns(bool);
    function getIsVoted(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function getVote(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function isReportSolved(uint256 _reportId) external view returns(bool);
    function reportResolution(uint256 _reportId) external view returns(bool);
    function getAmountReported(uint256 _reportId) external view returns(uint256);
    
    function setDisputePeriod(uint256 _timeFrame) external;
    function addCommitteeMembers(address[] memory _members) external;
    function removeCommitteeMembers(address[] memory _members) external;
    function losslessVote(uint256 _reportId, bool _vote) external;
    function tokenOwnersVote(uint256 _reportId, bool _vote) external;
    function committeeMemberVote(uint256 _reportId, bool _vote) external;
    function resolveReport(uint256 _reportId) external;
    function proposeWallet(uint256 _reportId, address wallet) external;
    function rejectWallet(uint256 _reportId) external;
    function retrieveFunds(uint256 _reportId) external;
    function retrieveCompensation() external;
    function claimCommitteeReward(uint256 _reportId) external;
    function setCompensationAmount(uint256 _amount) external;
    function losslessClaim(uint256 _reportId) external;
    function extaordinaryRetrieval(address[] calldata _address, ILERC20 _token) external;

    event NewCommitteeMembers(address[] _members);
    event CommitteeMembersRemoval(address[] _members);
    event LosslessTeamPositiveVote(uint256 indexed _reportId);
    event LosslessTeamNegativeVote(uint256 indexed _reportId);
    event TokenOwnersPositiveVote(uint256 indexed _reportId);
    event TokenOwnersNegativeVote(uint256 indexed _reportId);
    event CommitteeMemberPositiveVote(uint256 indexed _reportId, address indexed _member);
    event CommitteeMemberNegativeVote(uint256 indexed _reportId, address indexed _member);
    event ReportResolve(uint256 indexed _reportId, bool indexed _resolution);
    event WalletProposal(uint256 indexed _reportId, address indexed _wallet);
    event CommitteeMemberClaim(uint256 indexed _reportId, address indexed _member, uint256 indexed _amount);
    event CommitteeMajorityReach(uint256 indexed _reportId, bool indexed _result);
    event NewDisputePeriod(uint256 indexed _newPeriod);
    event WalletRejection(uint256 indexed _reportId);
    event FundsRetrieval(uint256 indexed _reportId, uint256 indexed _amount);
    event CompensationRetrieval(address indexed _wallet, uint256 indexed _amount);
    event LosslessClaim(ILERC20 indexed _token, uint256 indexed _reportID, uint256 indexed _amount);
    event ExtraordinaryProposalAccept(ILERC20 indexed _token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssStaking {
  function stakingToken() external returns(ILERC20);
  function losslessReporting() external returns(ILssReporting);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function stakingAmount() external returns(uint256);
  function getVersion() external pure returns (uint256);
  function getIsAccountStaked(uint256 _reportId, address _account) external view returns(bool);
  function getStakerCoefficient(uint256 _reportId, address _address) external view returns (uint256);
  function stakerClaimableAmount(uint256 _reportId) external view returns (uint256);
  function reportCoefficient(uint256 _reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setLssReporting(ILssReporting _losslessReporting) external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setStakingAmount(uint256 _stakingAmount) external;
  function stake(uint256 _reportId) external;
  function stakerClaim(uint256 _reportId) external;

  event NewStake(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event StakerClaim(address indexed _staker, ILERC20 indexed _token, uint256 indexed _reportID, uint256 _amount);
  event NewStakingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _newToken);
  event NewReportingContract(ILssReporting indexed _newContract);
  event NewGovernanceContract(ILssGovernance indexed _newContract);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessController.sol";

interface ILssReporting {
  function reporterReward() external returns(uint256);
  function losslessReward() external returns(uint256);
  function stakersReward() external returns(uint256);
  function committeeReward() external returns(uint256);
  function reportLifetime() external view returns(uint256);
  function reportingAmount() external returns(uint256);
  function reportCount() external returns(uint256);
  function stakingToken() external returns(ILERC20);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function getVersion() external pure returns (uint256);
  function getRewards() external view returns (uint256 _reporter, uint256 _lossless, uint256 _committee, uint256 _stakers);
  function report(ILERC20 _token, address _account) external returns (uint256);
  function reporterClaimableAmount(uint256 _reportId) external view returns (uint256);
  function getReportInfo(uint256 _reportId) external view returns(address _reporter,
        address _reportedAddress,
        address _secondReportedAddress,
        uint256 _reportTimestamps,
        ILERC20 _reportTokens,
        bool _secondReports,
        bool _reporterClaimStatus);
  
  function pause() external;
  function unpause() external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setReportingAmount(uint256 _reportingAmount) external;
  function setReporterReward(uint256 _reward) external;
  function setLosslessReward(uint256 _reward) external;
  function setStakersReward(uint256 _reward) external;
  function setCommitteeReward(uint256 _reward) external;
  function setReportLifetime(uint256 _lifetime) external;
  function secondReport(uint256 _reportId, address _account) external;
  function reporterClaim(uint256 _reportId) external;
  function retrieveCompensation(address _adr, uint256 _amount) external;

  event ReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event SecondReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event NewReportingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _token);
  event NewGovernanceContract(ILssGovernance indexed _adr);
  event NewReporterReward(uint256 indexed _newValue);
  event NewLosslessReward(uint256 indexed _newValue);
  event NewStakersReward(uint256 indexed _newValue);
  event NewCommitteeReward(uint256 indexed _newValue);
  event NewReportLifetime(uint256 indexed _newValue);
  event ReporterClaim(address indexed _reporter, uint256 indexed _reportId, uint256 indexed _amount);
  event CompensationRetrieve(address indexed _adr, uint256 indexed _amount);
}

pragma solidity ^0.8.0;

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}