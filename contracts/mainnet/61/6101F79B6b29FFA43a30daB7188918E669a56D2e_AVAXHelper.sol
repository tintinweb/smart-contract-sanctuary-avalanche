// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./interfaces/IAVAXHelper.sol";

contract AVAXHelper is IAVAXHelper {
    bytes32 internal immutable ASSET_ROLE;
    bytes32 internal immutable INDEX_MANAGER_ROLE;

    IAccessControl public override registry;
    IIndexRouter public override router;
    IManagedIndexFactory public override factory;

    modifier manageAssetRole(address _asset) {
        registry.grantRole(ASSET_ROLE, _asset);
        _;
        registry.revokeRole(ASSET_ROLE, _asset);
    }

    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "AVAXHelper: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address payable _router,
        address _factory
    ) {
        registry = IAccessControl(_registry);
        router = IIndexRouter(_router);
        factory = IManagedIndexFactory(_factory);

        ASSET_ROLE = keccak256("ASSET_ROLE");
        INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");
    }

    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset)
        external
        payable
        override
        onlyRole(INDEX_MANAGER_ROLE)
        manageAssetRole(_asset)
    {
        router.mintSwapValue{ value: msg.value }(_params);
    }

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external override onlyRole(INDEX_MANAGER_ROLE) manageAssetRole(_asset) {
        factory.createIndex(_assets, _weights, _nameDetails);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IIndexRouter.sol";
import "./IManagedIndexFactory.sol";

interface IAVAXHelper {
    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset) external payable;

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external;

    function registry() external view returns (IAccessControl);

    function router() external view returns (IIndexRouter);

    function factory() external view returns (IManagedIndexFactory);
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index router interface
/// @notice Describes methods allowing to mint and redeem index tokens
interface IIndexRouter {
    struct MintParams {
        address index;
        uint amountInBase;
        address recipient;
    }

    struct MintSwapParams {
        address index;
        address inputToken;
        uint amountInInputToken;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct MintSwapValueParams {
        address index;
        address recipient;
        MintQuoteParams[] quotes;
    }

    struct BurnParams {
        address index;
        uint amount;
        address recipient;
    }

    struct BurnSwapParams {
        address index;
        uint amount;
        address outputAsset;
        address recipient;
        BurnQuoteParams[] quotes;
    }

    struct MintQuoteParams {
        address asset;
        address swapTarget;
        uint buyAssetMinAmount;
        bytes assetQuote;
    }

    struct BurnQuoteParams {
        address swapTarget;
        uint buyAssetMinAmount;
        bytes assetQuote;
    }

    /// @notice WETH receive payable method
    receive() external payable;

    /// @notice Initializes IndexRouter
    /// @param _WETH WETH address
    /// @param _registry IndexRegistry contract address
    function initialize(address _WETH, address _registry) external;

    /// @notice Mints index in exchange for appropriate index tokens withdrawn from the sender
    /// @param _params Mint params structure containing mint amounts, token references and other details
    /// @return _amount Amount of index to be minted for the given assets
    function mint(MintParams calldata _params) external returns (uint _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwap(MintSwapParams calldata _params) external returns (uint _amount);

    /// @notice Mints index in exchange for specified asset withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    /// @return _amount Amount of index to be minted for the given amount of the specified asset
    function mintSwapWithPermit(
        MintSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Mints index in exchange for ETH withdrawn from the sender
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given value
    function mintSwapValue(MintSwapValueParams calldata _params) external payable returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burn(BurnParams calldata _params) external;

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @return _amounts Returns amount of tokens returned after burn
    function burnWithAmounts(BurnParams calldata _params) external returns (uint[] memory _amounts);

    /// @notice Burns index and returns corresponding amount of index tokens to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnWithPermit(
        BurnParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwap(BurnSwapParams calldata _params) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of specified asset to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    function burnSwapValue(BurnSwapParams calldata _params) external returns (uint _amount);

    /// @notice Burns index and returns corresponding amount of ETH to the sender
    /// @param _params Burn params structure containing burn recipient, amounts and other details
    /// @param _deadline Maximum unix timestamp at which the signature is still valid
    /// @param _v Last byte of the signed data
    /// @param _r The first 64 bytes of the signed data
    /// @param _s Bytes 64…128 of the signed data
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint _amount);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice WETH contract address
    /// @return Returns WETH contract address
    function WETH() external view returns (address);

    /// @notice Amount of index to be minted for the given amount of token
    /// @param _params Mint params structure containing mint recipient, amounts and other details
    /// @return _amount Amount of index to be minted for the given amount of token
    function mintSwapIndexAmount(MintSwapParams calldata _params) external view returns (uint _amount);

    /// @notice Amount of tokens returned after index burn
    /// @param _index Index contract address
    /// @param _amount Amount of index to burn
    /// @return _amounts Returns amount of tokens returned after burn
    function burnTokensAmount(address _index, uint _amount) external view returns (uint[] memory _amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Managed index factory interface
/// @notice Provides method for index creation
interface IManagedIndexFactory is IIndexFactory {
    event ManagedIndexCreated(address index, address[] _assets, uint8[] _weights);

    /// @notice Create managed index with assets and their weights
    /// @param _assets Assets list for the index
    /// @param _weights List of assets corresponding weights. Assets total weight should be equal to 255
    /// @param _nameDetails Name details data (name and symbol) to use for the created index
    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        NameDetails calldata _nameDetails
    ) external returns (address index);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index factory interface
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
interface IIndexFactory {
    struct NameDetails {
        string name;
        string symbol;
    }

    event SetVTokenFactory(address vTokenFactory);
    event SetDefaultMintingFeeInBP(address indexed account, uint16 mintingFeeInBP);
    event SetDefaultBurningFeeInBP(address indexed account, uint16 burningFeeInBP);
    event SetDefaultAUMScaledPerSecondsRate(address indexed account, uint AUMScaledPerSecondsRate);

    /// @notice Sets default index minting fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _mintingFeeInBP New minting fee value
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP) external;

    /// @notice Sets default index burning fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _burningFeeInBP New burning fee value
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP) external;

    /// @notice Sets reweighting logic address
    /// @param _reweightingLogic Reweighting logic address
    function setReweightingLogic(address _reweightingLogic) external;

    /// @notice Sets default AUM scaled per seconds rate that will be used for fee calculation
    /**
        @dev Will be set in FeePool on index creation.
        Effective management fee rate (annual, in percent, after dilution) is calculated by the given formula:
        fee = (rpow(scaledPerSecondRate, numberOfSeconds, 10*27) - 10**27) * totalSupply / 10**27, where:

        totalSupply - total index supply;
        numberOfSeconds - delta time for calculation period;
        scaledPerSecondRate - scaled rate, calculated off chain by the given formula:

        scaledPerSecondRate = ((1 + k) ** (1 / 365 days)) * AUMCalculationLibrary.RATE_SCALE_BASE, where:
        k = (aumFeeInBP / BP) / (1 - aumFeeInBP / BP);

        Note: rpow and RATE_SCALE_BASE are provided by AUMCalculationLibrary
        More info: https://docs.enzyme.finance/fee-formulas/management-fee

        After value calculated off chain, scaledPerSecondRate is set to setDefaultAUMScaledPerSecondsRate
    */
    /// @param _AUMScaledPerSecondsRate New AUM scaled per seconds rate
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate) external;

    /// @notice Withdraw fee balance to fee pool for a given index
    /// @param _index Index to withdraw fee balance from
    function withdrawToFeePool(address _index) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Minting fee in base point (BP) format
    /// @return Returns minting fee in base point (BP) format
    function defaultMintingFeeInBP() external view returns (uint16);

    /// @notice Burning fee in base point (BP) format
    /// @return Returns burning fee in base point (BP) format
    function defaultBurningFeeInBP() external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    ///         See setDefaultAUMScaledPerSecondsRate method description for more details.
    /// @return Returns AUM scaled per seconds rate
    function defaultAUMScaledPerSecondsRate() external view returns (uint);

    /// @notice Reweighting logic address
    /// @return Returns reweighting logic address
    function reweightingLogic() external view returns (address);
}