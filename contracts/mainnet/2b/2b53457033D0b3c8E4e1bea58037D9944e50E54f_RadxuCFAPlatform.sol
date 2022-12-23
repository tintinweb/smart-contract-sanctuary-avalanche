// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./RadxuCFAPlatformReader.sol";

/// @custom:security-contact [email protected]
contract RadxuCFAPlatform is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    RadxuCFAPlatformReader
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _priceGetterAddress,
        address _radxuTokenInteractorAddress,
        address _treasuryAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(INITIALIZER_ROLE, msg.sender);

        treasuryAddress = payable(_treasuryAddress);

        CFACost = 10 ether;
        CFADistribution = 0.1 ether;
        CFACap = 40;

        CFAClaimLimit = 86400;
        CFAUsdMonthlyFee = 3;

        thirtyDaySeconds = 2592000;
        sixtyDaySeconds = 5184000;
        ninetyDaySeconds = 7776000;

        priceGetter = PriceGetter(_priceGetterAddress);
        radxuTokenInteractor = RadxuTokenInteractor(
            payable(_radxuTokenInteractorAddress)
        );
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function purchaseCFA(uint _amount) public whenNotPaused {
        _purchaseCFA(_amount, false);
    }

    function _purchaseCFA(uint _amount, bool _compounded) internal {
        require(_amount <= 20, "WA");
        uint payment;
        if (!_compounded) payment += CFACost * _amount;

        _filterAndAddCFAToAddress(msg.sender, _amount, _compounded);

        if (!_compounded) {
            uint distributionTokens = (payment * 975) / 1000;
            radxuTokenInteractor.addLiquidityToDex(
                distributionTokens,
                payment - distributionTokens
            );
        }
        emit purchasedCFA(_amount);
    }

    function _setupNewCFAs(
        address _CFAOwnerAddress,
        uint _activeCFAs,
        uint _inactiveCFAs,
        bool _compounded
    ) internal {
        uint feeMonths;
        (_activeCFAs + _inactiveCFAs == (CFACap / 2))
            ? feeMonths = 2
            : feeMonths = 1;

        if (_activeCFAs > 0) {
            uint id = totalCFACount;
            for (uint i; i < _activeCFAs; i++) {
                _addCFAsToUser(
                    id++,
                    _CFAOwnerAddress,
                    _compounded,
                    feeMonths,
                    true
                );
            }
            emit createdActiveCFAs(_activeCFAs);
            totalCFACount += _activeCFAs;
            totalActiveCFACount += _activeCFAs;
        }

        if (_inactiveCFAs > 0) {
            uint id = totalCFACount;
            for (uint i; i < _inactiveCFAs; i++) {
                _addCFAsToUser(
                    id++,
                    _CFAOwnerAddress,
                    _compounded,
                    feeMonths,
                    false
                );
            }
            emit createdInactiveCFAs(_inactiveCFAs);
            totalCFACount += _inactiveCFAs;
            totalInactiveCFACount += _inactiveCFAs;
        }
    }

    function _addCFAsToUser(
        uint _id,
        address _user,
        bool _compounded,
        uint _feeMonths,
        bool status
    ) internal {
        CFAInfo memory info;
        info.id = _id;
        info.owner = _user;
        info.creationTimestamp = block.timestamp;
        info.isCompounded = _compounded;
        info.isActive = status;
        info.isDeleted = false;
        info.isDistributionAvailable = status;
        info.lastClaimTimestamp = block.timestamp;
        info.nextAvailableClaimTimestamp = block.timestamp + CFAClaimLimit;
        info.operationalUntilTimestamp =
            block.timestamp +
            (thirtyDaySeconds * _feeMonths);

        CFAs[_id] = info;
        CFAsByUser[_user].push(_id);

        CFAIdInfo memory idInfo;
        idInfo.owner = _user;
        idInfo.index = _id;

        userByCFAId[_id] = idInfo;
    }

    function _updateCFAFee(uint _CFAId, address _user) internal {
        CFAIdInfo memory idInfo = userByCFAId[_CFAId];
        require(idInfo.owner == _user, "OM");
        CFAInfo memory CFAInfoData = CFAs[_CFAId];

        if (CFAInfoData.isActive) {
            uint oldOperationalUntilTimestamp = CFAInfoData
                .operationalUntilTimestamp;

            if (block.timestamp >= oldOperationalUntilTimestamp) {
                uint timeElapsed = block.timestamp -
                    oldOperationalUntilTimestamp;

                if (
                    timeElapsed >= ninetyDaySeconds &&
                    isPreDistributionUser(_user)
                ) {
                    (, uint unPaidMonths, , , , , , , ) = getCFAPayFeeData(
                        _CFAId
                    );
                    oldOperationalUntilTimestamp +=
                        unPaidMonths *
                        thirtyDaySeconds;
                } else {
                    if (timeElapsed > sixtyDaySeconds) {
                        oldOperationalUntilTimestamp += ninetyDaySeconds;
                    } else if (timeElapsed > thirtyDaySeconds) {
                        oldOperationalUntilTimestamp += sixtyDaySeconds;
                    } else {
                        oldOperationalUntilTimestamp += thirtyDaySeconds;
                    }
                }
            }
            CFAInfoData.operationalUntilTimestamp =
                oldOperationalUntilTimestamp +
                thirtyDaySeconds;
            CFAInfoData.isDistributionAvailable = true;
            CFAs[_CFAId] = CFAInfoData;
        }
    }

    function payCFAFee(uint _CFAId) public payable whenNotPaused {
        _updateCFAFee(_CFAId, msg.sender);
        (, , , , , , , , uint avaxAmount) = getCFAPayFeeData(_CFAId);
        _payFeeAmount(avaxAmount);
        emit paidIndividualFees(avaxAmount);
    }

    function payAllAvailableCFAFees() public payable whenNotPaused {
        address user = msg.sender;
        uint[] memory CFAIds = CFAsByUser[user];
        for (uint i; i < CFAIds.length; i++) {
            _updateCFAFee(CFAIds[i], user);
        }
        (, , , , , , , , , , uint avaxPayAmount) = getUserPayAllCFAFeesData(
            user,
            1
        );
        _payFeeAmount(avaxPayAmount);
        emit paidAllFees(avaxPayAmount);
    }

    function _payFeeAmount(uint _avaxAmount) internal {
        require(msg.value >= _avaxAmount, "WP");
        uint returnAmt = msg.value - _avaxAmount;
        bool success = false;
        (success, ) = address(treasuryAddress).call{
            value: _avaxAmount,
            gas: 200000
        }("");
        if (returnAmt > 0) {
            payable(msg.sender).transfer(returnAmt);
        }
    }

    function _claimCFADistribution(
        uint _CFAId,
        address _user,
        bool _isCompounding
    ) internal returns (uint distribution) {
        CFAInfo memory CFAInfoData = CFAs[_CFAId];
        require(CFAInfoData.owner == _user, "OM");
        require(
            CFAInfoData.nextAvailableClaimTimestamp <= block.timestamp,
            "NC"
        );
        if (CFAInfoData.isDistributionAvailable) {
            distribution = getDistributionByCFA(CFAInfoData.lastClaimTimestamp);
            CFAInfoData.lastClaimTimestamp = block.timestamp;
            if (!_isCompounding) {
                CFAInfoData.nextAvailableClaimTimestamp =
                    block.timestamp +
                    CFAClaimLimit;
            }
            CFAs[_CFAId] = CFAInfoData;
        }
    }

    function claimSpecificCFADistribution(uint _CFAId) public whenNotPaused {
        uint distribution = _claimCFADistribution(_CFAId, msg.sender, false);

        radxuTokenInteractor.transferDistributions(msg.sender, distribution);

        emit claimedIndividualDistributions(distribution);
    }

    function claimAllDistributions() public whenNotPaused {
        address user = msg.sender;
        uint[] memory CFAIds = CFAsByUser[user];
        uint distribution;
        for (uint i; i < CFAIds.length; i++) {
            if (!CFAs[CFAIds[i]].isDistributionAvailable) continue;
            if (
                CFAs[CFAIds[i]].lastClaimTimestamp >=
                block.timestamp - CFAClaimLimit
            ) continue;
            distribution += _claimCFADistribution(CFAIds[i], user, false);
        }
        radxuTokenInteractor.transferDistributions(user, distribution);
        emit claimedAllDistributions(distribution);
    }

    function compoundDistributions(uint _CFAAmount) public whenNotPaused {
        address user = msg.sender;
        uint[] memory CFAIds = CFAsByUser[user];
        uint compoundRequiredPayment;
        uint internalCFACost = CFACost;
        uint internalCFAAmount = _CFAAmount;
        compoundRequiredPayment += internalCFACost * internalCFAAmount;

        uint distribution;
        for (uint i; i < CFAIds.length; i++) {
            distribution += _claimCFADistribution(CFAIds[i], user, true);
            if (distribution >= compoundRequiredPayment) {
                break;
            }
        }
        if (distribution < compoundRequiredPayment) revert("ID");
        distribution -= compoundRequiredPayment;
        _purchaseCFA(_CFAAmount, true);
        radxuTokenInteractor.transferDistributions(user, distribution);

        emit compoundedDistributions(_CFAAmount);
    }

    function addCFAsToAddress(address _userAddress, uint _CFAAmount)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _filterAndAddCFAToAddress(_userAddress, _CFAAmount, true);
        emit issuedCFAs(_CFAAmount);
    }

    function _filterAndAddCFAToAddress(
        address _userAddress,
        uint _CFAAmount,
        bool _compounded
    ) internal {
        uint newActiveCFAs = CFACap - getUserActiveCFAs(_userAddress);

        (newActiveCFAs <= _CFAAmount)
            ? _setupNewCFAs(
                _userAddress,
                newActiveCFAs,
                _CFAAmount - newActiveCFAs,
                _compounded
            )
            : _setupNewCFAs(_userAddress, _CFAAmount, 0, _compounded);
    }

    function reDistributeCFAsToAddress(
        address _oldUser,
        address _newUser,
        uint[] calldata _CFAIds
    ) public onlyRole(OPERATOR_ROLE) {
        uint[] storage CFAsForOldUser = CFAsByUser[_oldUser];
        uint[] storage CFAsForNewUser = CFAsByUser[_newUser];
        for (uint i; i < _CFAIds.length; i++) {
            CFAIdInfo memory idInfo = userByCFAId[_CFAIds[i]];
            require(idInfo.owner == _oldUser, "OM");

            CFAsForNewUser.push(CFAsForOldUser[idInfo.index]);
            CFAsForOldUser[idInfo.index] = CFAsForOldUser[
                CFAsForOldUser.length - 1
            ];
            CFAsForOldUser.pop();

            uint updatedOldUserCFA = CFAsForOldUser[idInfo.index];
            userByCFAId[updatedOldUserCFA].index = idInfo.index;

            idInfo.owner = _newUser;
            idInfo.index = CFAsForNewUser.length - 1;

            CFAInfo memory CFAInfoData = CFAs[_CFAIds[i]];
            CFAInfoData.owner = _newUser;
            CFAInfoData.isCompounded = false;
            CFAInfoData.isActive = true;
            CFAInfoData.isDeleted = false;
            CFAInfoData.isDistributionAvailable = true;
            CFAInfoData.lastClaimTimestamp = block.timestamp;
            CFAInfoData.nextAvailableClaimTimestamp =
                block.timestamp +
                CFAClaimLimit;
            CFAInfoData.operationalUntilTimestamp =
                block.timestamp +
                thirtyDaySeconds;
            CFAs[_CFAIds[i]] = CFAInfoData;
        }
        emit redistributedCFAs(_newUser, _CFAIds.length);
    }

    function removeCFAs(uint[] calldata _CFAIds)
        public
        onlyRole(OPERATOR_ROLE)
    {
        for (uint i; i < _CFAIds.length; i++) {
            CFAInfo memory CFAInfoData = CFAs[_CFAIds[i]];
            (CFAInfoData.isActive)
                ? totalActiveCFACount--
                : totalInactiveCFACount--;
            CFAInfoData.isDeleted = true;
            CFAInfoData.isActive = false;
            CFAInfoData.isDistributionAvailable = false;
            CFAs[_CFAIds[i]] = CFAInfoData;
        }
        totalDeletedCFACount += _CFAIds.length;
    }

    function setCFAsUnclaimable(uint[] calldata _CFAIds)
        public
        onlyRole(OPERATOR_ROLE)
    {
        for (uint i; i < _CFAIds.length; i++) {
            CFAs[_CFAIds[i]].isDistributionAvailable = false;
        }
        emit setUnclaimableCFAs(_CFAIds);
    }

    function activateCFA(uint[] calldata _CFAIds, uint _operationStartTimestamp)
        public
        onlyRole(OPERATOR_ROLE)
    {
        for (uint i; i < _CFAIds.length; i++) {
            CFAInfo memory CFAInfoData = CFAs[_CFAIds[i]];
            CFAInfoData.isActive = true;
            CFAInfoData.isDistributionAvailable = true;
            CFAInfoData.lastClaimTimestamp = block.timestamp;
            CFAInfoData.nextAvailableClaimTimestamp =
                _operationStartTimestamp +
                CFAClaimLimit;
            CFAInfoData.operationalUntilTimestamp =
                _operationStartTimestamp +
                thirtyDaySeconds;
            CFAs[_CFAIds[i]] = CFAInfoData;
        }
        emit activatedCFAs(_CFAIds, _operationStartTimestamp);
    }

    function setInitialUserData(CFAInfo[] calldata _CFAsData)
        external
        onlyRole(INITIALIZER_ROLE)
    {
        for (uint i; i < _CFAsData.length; i++) {
            // Fill CFAsData
            CFAs[_CFAsData[i].id] = _CFAsData[i];
            // Fill UserByCFAId
            CFAIdInfo memory idInfo;
            idInfo.owner = _CFAsData[i].owner;
            idInfo.index = _CFAsData[i].id;
            userByCFAId[idInfo.index] = idInfo;
            // FillCFAsByUser
            CFAsByUser[idInfo.owner].push(idInfo.index);
            // Fill counters
            (_CFAsData[i].isActive)
                ? totalActiveCFACount++
                : totalInactiveCFACount++;
            if (_CFAsData[i].isDeleted) {
                totalDeletedCFACount++;
            }
        }
        totalCFACount += _CFAsData.length;
    }

    function setPredistributionParticipants(
        address[] calldata _preDistributionParticipants
    ) external onlyRole(INITIALIZER_ROLE) {
        for (uint i; i < _preDistributionParticipants.length; i++) {
            preDistributionParticipants.push(_preDistributionParticipants[i]);
        }
    }

    function setFeeValue(uint _feeValue) external onlyRole(OPERATOR_ROLE) {
        require(_feeValue > 0, "IN");
        CFAUsdMonthlyFee = _feeValue;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PriceGetter.sol";
import "./interfaces/IRadxuCFAPlatform.sol";
import "./RadxuTokenInteractor.sol";
import "./RadxuCFAPlatform.sol";

/// @custom:security-contact [email protected]
contract RadxuCFAPlatformReader is Initializable, IRadxuCFAPlatform {
    address public communityTokenAddress;
    uint public totalCFACount;
    uint public totalActiveCFACount;
    uint public totalInactiveCFACount;
    uint public totalDeletedCFACount;
    address priceGetterContractAddress;
    address radxuTokenInteractorAddress;

    address[] preDistributionParticipants;

    uint public CFACost;
    uint public CFADistribution;
    uint public CFACap;
    uint public CFAUsdMonthlyFee;
    uint public CFAClaimLimit;

    address payable treasuryAddress;

    uint thirtyDaySeconds;
    uint sixtyDaySeconds;
    uint ninetyDaySeconds;

    mapping(uint => CFAIdInfo) public userByCFAId;
    mapping(address => uint[]) public CFAsByUser;
    mapping(uint => CFAInfo) public CFAs;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");

    PriceGetter internal priceGetter;
    RadxuTokenInteractor internal radxuTokenInteractor;

    function getCFAClaimableDistribution(uint _CFAId)
        public
        view
        returns (uint)
    {
        CFAInfo memory CFAInfoData = CFAs[_CFAId];
        if (!CFAInfoData.isDistributionAvailable) return 0;
        if (CFAInfoData.nextAvailableClaimTimestamp > block.timestamp) return 0;
        return getDistributionByCFA(CFAInfoData.lastClaimTimestamp);
    }

    function getCFAUnClaimableDistribution(uint _CFAId)
        public
        view
        returns (uint)
    {
        CFAInfo memory CFAInfoData = CFAs[_CFAId];
        if (!CFAInfoData.isActive || CFAInfoData.isDeleted) return 0;
        if (
            CFAInfoData.isDistributionAvailable &&
            uint(CFAInfoData.nextAvailableClaimTimestamp) <= block.timestamp
        ) return 0;
        return getDistributionByCFA(CFAInfoData.lastClaimTimestamp);
    }

    function getUserTotalCFAs(address _user) public view returns (uint) {
        return getUserActiveCFAs(_user) + getUserInactiveCFAs(_user);
    }

    function getUserActiveCFAs(address _user) public view returns (uint count) {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            if (CFAs[CFAIds[i]].isActive) count += 1;
        }
    }

    function getUserInactiveCFAs(address _user)
        public
        view
        returns (uint count)
    {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            if (!CFAs[CFAIds[i]].isActive && !CFAs[CFAIds[i]].isDeleted)
                count += 1;
        }
    }

    function getUserPurchasedCFAs(address _user)
        public
        view
        returns (uint count)
    {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            if (!CFAs[CFAIds[i]].isCompounded) count += 1;
        }
    }

    function getUserCompoundedCFAs(address _user)
        public
        view
        returns (uint count)
    {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            if (CFAs[CFAIds[i]].isCompounded) count += 1;
        }
    }

    function getUserTotalDistributions(address _user)
        public
        view
        returns (uint)
    {
        return
            getUserClaimableDistributions(_user) +
            getUserUnClaimableDistributions(_user);
    }

    function getUserClaimableDistributions(address _user)
        public
        view
        returns (uint allDistribution)
    {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            allDistribution += getCFAClaimableDistribution(CFAIds[i]);
        }
        return allDistribution;
    }

    function getUserUnClaimableDistributions(address _user)
        public
        view
        returns (uint allDistribution)
    {
        uint[] memory CFAIds = CFAsByUser[_user];
        for (uint i = 0; i < CFAIds.length; i++) {
            allDistribution += getCFAUnClaimableDistribution(CFAIds[i]);
        }
        return allDistribution;
    }

    function getUserRemainingActiveCFAs(address _user)
        public
        view
        returns (uint remainingActiveCFAs)
    {
        uint[] memory CFAIds = CFAsByUser[_user];

        uint activeCount;
        for (uint index = 0; index < CFAIds.length; index++) {
            if (CFAs[CFAIds[index]].isActive) {
                activeCount += 1;
            }
        }
        remainingActiveCFAs = CFACap - activeCount;
    }

    function getCFAPayFeeData(uint _CFAId)
        public
        view
        returns (
            uint paidCFAMonths,
            uint unPaidCFAMonths,
            uint usdPayAmountPaidPeriod,
            uint usdDiscountedPayAmountPaidPeriod,
            uint usdPayAmountUnPaidPeriod,
            uint totalUsdPayAmount,
            uint totalAvaxPayAmount,
            uint totalDiscountedUsdPayAmount,
            uint totalDiscountedAvaxPayAmount
        )
    {
        CFAInfo memory CFAInfoData = CFAs[_CFAId];
        if (!CFAInfoData.isActive) return (0, 0, 0, 0, 0, 0, 0, 0, 0);

        if (CFAInfoData.operationalUntilTimestamp < block.timestamp) {
            unPaidCFAMonths = _ceilDiv(
                block.timestamp - CFAInfoData.operationalUntilTimestamp,
                thirtyDaySeconds
            );
        } else {
            paidCFAMonths =
                (CFAInfoData.operationalUntilTimestamp - block.timestamp) /
                thirtyDaySeconds;
        }

        usdPayAmountPaidPeriod = CFAUsdMonthlyFee;
        usdDiscountedPayAmountPaidPeriod = 2;
        usdPayAmountUnPaidPeriod = unPaidCFAMonths * CFAUsdMonthlyFee;
        totalUsdPayAmount = usdPayAmountPaidPeriod + usdPayAmountUnPaidPeriod;
        totalAvaxPayAmount = _calculatePaymentAvaxAmount(totalUsdPayAmount);
        totalDiscountedUsdPayAmount =
            usdDiscountedPayAmountPaidPeriod +
            usdPayAmountUnPaidPeriod;
        totalDiscountedAvaxPayAmount = _calculatePaymentAvaxAmount(
            totalDiscountedUsdPayAmount
        );
    }

    function getUserPayAllCFAFeesData(address _user, uint _months)
        public
        view
        returns (
            uint currentTotalPaidMonths,
            uint currentTotalUnPaidMonths,
            uint paidCFAAmount,
            uint unPaidCFAAmount,
            uint usdPayAmountPaidCFAs,
            uint usdDiscountedPayAmountPaidCFAs,
            uint usdPayAmountUnPaidCFAs,
            uint totalUsdPayAmount,
            uint totalAvaxPayAmount,
            uint totalDiscountedUsdPayAmount,
            uint totalDiscountedAvaxPayAmount
        )
    {
        uint[] memory CFAIds = CFAsByUser[_user];

        currentTotalPaidMonths = 0;
        currentTotalUnPaidMonths = 0;

        for (uint index = 0; index < CFAIds.length; index++) {
            CFAInfo memory CFAInfoData = CFAs[CFAIds[index]];
            if (CFAInfoData.isActive) {
                if (CFAInfoData.operationalUntilTimestamp < block.timestamp) {
                    unPaidCFAAmount++;
                    currentTotalUnPaidMonths += _ceilDiv(
                        block.timestamp - CFAInfoData.operationalUntilTimestamp,
                        thirtyDaySeconds
                    );
                } else {
                    paidCFAAmount++;
                    currentTotalPaidMonths +=
                        (CFAInfoData.operationalUntilTimestamp -
                            block.timestamp) /
                        thirtyDaySeconds;
                }
            }
        }

        usdPayAmountPaidCFAs =
            _months *
            (paidCFAAmount + unPaidCFAAmount) *
            CFAUsdMonthlyFee;

        usdDiscountedPayAmountPaidCFAs =
            _months *
            (paidCFAAmount + unPaidCFAAmount) *
            2;

        usdPayAmountUnPaidCFAs = currentTotalUnPaidMonths * CFAUsdMonthlyFee;

        totalUsdPayAmount = usdPayAmountPaidCFAs + usdPayAmountUnPaidCFAs;

        totalDiscountedUsdPayAmount =
            usdDiscountedPayAmountPaidCFAs +
            usdPayAmountUnPaidCFAs;

        totalAvaxPayAmount = _calculatePaymentAvaxAmount(totalUsdPayAmount);

        totalDiscountedAvaxPayAmount = _calculatePaymentAvaxAmount(
            usdDiscountedPayAmountPaidCFAs + usdPayAmountUnPaidCFAs
        );
    }

    function _ceilDiv(uint a, uint b) internal pure returns (uint) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function _calculatePaymentAvaxAmount(uint _usdPayAmount)
        internal
        view
        returns (uint avaxAmount)
    {
        uint avaxPayAmount = ((_usdPayAmount * (10**10)) /
            getAvaxUsdLatestPrice()) + 1;
        avaxAmount = avaxPayAmount * (10**16);
    }

    function getAvaxUsdLatestPrice() public view returns (uint) {
        return priceGetter.getPrice("AVAX/USD");
    }

    function getUserCFAIds(address _user)
        public
        view
        returns (uint[] memory CFAIds)
    {
        CFAIds = CFAsByUser[_user];
    }

    function getDistributionByCFA(uint _lastTime) public view returns (uint) {
        uint historicCFADistribution = CFADistribution;
        uint lastCheckPoint = block.timestamp;
        uint timeElapsed = lastCheckPoint - _lastTime;

        return (historicCFADistribution * timeElapsed) / CFAClaimLimit;
    }

    function getCFADataById(uint _CFAId)
        public
        view
        returns (CFAInfo memory CFAData)
    {
        CFAData = CFAs[_CFAId];
    }

    function isPreDistributionUser(address _user) public view returns (bool) {
        for (uint i; i < preDistributionParticipants.length; i++) {
            if (preDistributionParticipants[i] == _user) {
                return true;
            }
        }
        return false;
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPriceGetter.sol";

/// @custom:security-contact [email protected]
contract PriceGetter is Pausable, AccessControl, IPriceGetter {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    mapping(string => priceFeedData) public priceFeeds;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addPriceFeed(
        string memory _priceFeedName,
        address _priceOracleAddress
    ) public onlyRole(OPERATOR_ROLE) returns (bool success) {
        require(
            bytes(_priceFeedName).length >= 7,
            "Minimum length not accomplished"
        );
        if (isPriceFeedExists(_priceFeedName)) revert("PriceFeedAlreadyExists");
        priceFeeds[_priceFeedName].priceFeedAddress = _priceOracleAddress;
        priceFeeds[_priceFeedName].isEntity = true;
        emit addedPriceFeed(_priceFeedName, _priceOracleAddress);
        return true;
    }

    function updatePriceFeed(
        string memory _priceFeedName,
        address _priceOracleAddress
    ) public onlyRole(OPERATOR_ROLE) returns (bool success) {
        if (!isPriceFeedExists(_priceFeedName)) revert("PriceFeedNotExists");
        priceFeeds[_priceFeedName].priceFeedAddress = _priceOracleAddress;
        emit updatedPriceFeed(_priceFeedName, _priceOracleAddress);
        return true;
    }

    function deletePriceFeed(string memory _priceFeedName)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool success)
    {
        if (!isPriceFeedExists(_priceFeedName)) revert("PriceFeedNotExists");
        priceFeeds[_priceFeedName].isEntity = false;
        emit deletedPriceFeed(_priceFeedName);
        return true;
    }

    function isPriceFeedExists(string memory _priceFeedName)
        public
        view
        returns (bool)
    {
        return priceFeeds[_priceFeedName].isEntity;
    }

    function getPrice(string memory _priceFeedName) public view returns (uint) {
        if (!isPriceFeedExists(_priceFeedName)) revert("PriceFeedNotExists");
        address priceOracleAddress = priceFeeds[_priceFeedName]
            .priceFeedAddress;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceOracleAddress
        );
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IRadxuCFAPlatform {
    struct CFAInfo {
        uint id;
        address owner;
        uint creationTimestamp;
        bool isCompounded;
        bool isActive;
        bool isDeleted;
        bool isDistributionAvailable;
        uint lastClaimTimestamp;
        uint nextAvailableClaimTimestamp;
        uint operationalUntilTimestamp;
    }
    struct CFAIdInfo {
        address owner;
        uint index;
    }

    event purchasedCFA(uint indexed);
    event createdActiveCFAs(uint indexed);
    event createdInactiveCFAs(uint indexed);
    event addedLiquidityToDex();
    event paidIndividualFees(uint indexed);
    event paidAllFees(uint indexed);
    event claimedIndividualDistributions(uint indexed);
    event claimedAllDistributions(uint indexed);
    event compoundedDistributions(uint indexed);

    event issuedCFAs(uint indexed);
    event redistributedCFAs(address indexed, uint indexed);
    event removedCFAs(uint[] indexed);
    event setUnclaimableCFAs(uint[] indexed);
    event activatedCFAs(uint[] indexed, uint indexed);

    event executedHalving(uint indexed, uint indexed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./TraderJoe/libraries/JoeLibrary.sol";
import "./TraderJoe/interfaces/IJoeRouter02.sol";

/// @custom:security-contact [email protected]
contract RadxuTokenInteractor is AccessControl {
    address distributionPoolAddress;
    address communityTokenAddress;
    address joeRouterAddress;
    address joeFactoryAddress;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(
        address _distributionPoolAddress,
        address _communityTokenAddress,
        address _joeRouterAddress,
        address _joeFactoryAddress
    ) {
        distributionPoolAddress = payable(_distributionPoolAddress);
        communityTokenAddress = _communityTokenAddress;
        joeRouterAddress = _joeRouterAddress;
        joeFactoryAddress = _joeFactoryAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        IERC20Upgradeable(communityTokenAddress).approve(
            joeRouterAddress,
            type(uint256).max
        );
    }

    function addLiquidityToDex(
        uint256 distributionTokens,
        uint256 liquidityTokens
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            IERC20Upgradeable(communityTokenAddress).transferFrom(
                tx.origin,
                distributionPoolAddress,
                distributionTokens
            ),
            "TF"
        );
        require(
            IERC20Upgradeable(communityTokenAddress).transferFrom(
                tx.origin,
                address(this),
                liquidityTokens
            ),
            "TF"
        );
        uint256 swapToAvaxTokens = liquidityTokens / 2;
        address[] memory paths = new address[](2);
        paths[0] = communityTokenAddress;
        paths[1] = IJoeRouter02(joeRouterAddress).WAVAX();
        address wAvax = IJoeRouter02(joeRouterAddress).WAVAX();
        (uint256 reserveA, uint256 reserveB) = JoeLibrary.getReserves(
            joeFactoryAddress,
            communityTokenAddress,
            wAvax
        );
        IJoeRouter02(joeRouterAddress).swapExactTokensForAVAX(
            swapToAvaxTokens,
            0,
            paths,
            address(this),
            block.timestamp
        );
        uint256 avaxBalance = address(this).balance;
        wAvax = IJoeRouter02(joeRouterAddress).WAVAX();
        (reserveA, reserveB) = JoeLibrary.getReserves(
            joeFactoryAddress,
            communityTokenAddress,
            wAvax
        );
        if (reserveA == 0 && reserveB == 0) return;
        uint256 liquidityAvax = JoeLibrary.quote(
            swapToAvaxTokens,
            reserveA,
            reserveB
        );
        if (liquidityAvax > avaxBalance) return;
        IJoeRouter02(joeRouterAddress).addLiquidityAVAX{value: avaxBalance}(
            communityTokenAddress,
            swapToAvaxTokens,
            0,
            0,
            address(this),
            block.timestamp
        );
        (reserveA, reserveB) = JoeLibrary.getReserves(
            joeFactoryAddress,
            communityTokenAddress,
            wAvax
        );
    }

    function transferDistributions(address receiver, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
    {
        IERC20Upgradeable(communityTokenAddress).transferFrom(
            distributionPoolAddress,
            receiver,
            amount
        );
    }

    receive() external payable {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPriceGetter {
    struct priceFeedData {
        address priceFeedAddress;
        bool isEntity;
    }

    event addedPriceFeed(string, address);
    event updatedPriceFeed(string, address);
    event deletedPriceFeed(string);

    function addPriceFeed(
        string memory _priceFeedName,
        address _priceOracleAddress
    ) external returns (bool success);

    function updatePriceFeed(
        string memory _priceFeedName,
        address _priceOracleAddress
    ) external returns (bool success);

    function deletePriceFeed(string memory _priceFeedName)
        external
        returns (bool success);

    function isPriceFeedExists(string memory _priceFeedName)
        external
        view
        returns (bool);

    function getPrice(string memory _priceFeedName)
        external
        view
        returns (uint);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "../interfaces/IJoePair.sol";
import "../interfaces/IJoeFactory.sol";

import "./SafeMath.sol";

library JoeLibrary {
    using SafeMathJoe for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(
        //     uint160(
        //         uint256(
        //             keccak256(
        //                 abi.encodePacked(
        //                     hex"ff",
        //                     factory,
        //                     keccak256(abi.encodePacked(token0, token1)),
        //                     hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91" // init code fuji
        //                 )
        //             )
        //         )
        //     )
        // );
        pair = IJoeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "JoeLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

import "./IJoeRouter01.sol";

pragma solidity ^0.8.9;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IJoeRouter01 {
    function factory() external view returns (address);

    function WAVAX() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}