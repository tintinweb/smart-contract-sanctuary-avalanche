// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// External Imports
import {StructERC1155} from "./StructERC1155.sol";

/// Internal Imports
import {GACManaged} from "../common/GACManaged.sol";
import {IGAC} from "../../interfaces/IGAC.sol";
import {IFEYFactory} from "../../interfaces/IFEYFactory.sol";

/**
 * @title StructSP Token
 * @notice A simple implementation of ERC1155 token using OpenZeppelin libraries
 * @dev This contract implements the StructSP Token, which is an ERC1155 token using OpenZeppelin libraries.
 * It also makes use of GACManaged for access control.
 * @author Struct Finance
 */
contract StructSPToken is StructERC1155, GACManaged {
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    IFEYFactory private feyProductFactory;

    constructor(IGAC _globalAccessControl, IFEYFactory _feyProductFactory) {
        __GACManaged_init(_globalAccessControl);
        feyProductFactory = _feyProductFactory;
    }

    /**
     * @dev Transfers tokens from one address to another
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the token to transfer
     * @param amount The amount of the token to transfer
     * @param data Additional data with no specified format
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)
        public
        virtual
        override
        gacPausable
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Transfers multiple types of tokens from one address to another
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param ids The IDs of the tokens to transfer
     * @param amounts The amounts of the tokens to transfer
     * @param data Additional data with no specified format
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override gacPausable {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Mints tokens and assigns them to an address
     * @param to The address to assign the minted tokens to
     * @param id The ID of the token to mint
     * @param amount The amount of the token to mint
     * @param data Additional data with no specified format
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        virtual
        gacPausable
        onlyRole(PRODUCT)
    {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Mints multiple types of tokens and assigns them to an address
     * @param to The address to assign the minted tokens to
     * @param ids The IDs of the tokens to mint
     * @param amounts The amounts of the tokens to mint
     * @param data Additional data with no specified format
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        virtual
        gacPausable
        onlyRole(PRODUCT)
    {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @notice Burn a certain amount of a specific token ID.
     * @param from The address of the token owner.
     * @param id The ID of the token to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) public virtual onlyRole(PRODUCT) gacPausable {
        require(_msgSender() == from || isApprovedForAll[from][_msgSender()], "NOT_AUTHORIZED");
        _burn(from, id, amount);
    }

    /**
     * @notice Burn multiple amounts of different token IDs.
     * @param from The address of the token owner.
     * @param ids The IDs of the tokens to burn.
     * @param amounts The amounts of tokens to burn.
     */
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts)
        public
        virtual
        onlyRole(PRODUCT)
        gacPausable
    {
        require(_msgSender() == from || isApprovedForAll[from][_msgSender()], "NOT_AUTHORIZED");
        _batchBurn(from, ids, amounts);
    }

    /**
     * @notice Hook that restricts the token transfers if the state of the associated product is not `INVESTED`.
     * @dev Also restricts the minting once the deposits are closed for the associated product.
     * @param operator The address performing the operation.
     * @param from The address from which the tokens are transferred.
     * @param to The address to which the tokens are transferred.
     * @param ids The IDs of the tokens being transferred.
     * @param amounts The amounts of tokens being transferred.
     * @param data Additional data with no specified format.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override gacPausable {
        /// if mint, check if minting is enabled for the product
        if (from == address(0)) {
            uint256 idsLength = ids.length;
            for (uint256 i = 0; i < idsLength;) {
                require(feyProductFactory.isMintActive(ids[i]), "MINT_DISABLED");

                unchecked {
                    i++;
                }
            }
            /// for transfers (excluding `burn()`), check if transfer is enabled for the product
        } else if (to != address(0)) {
            uint256 idsLength = ids.length;
            for (uint256 i = 0; i < idsLength;) {
                require(feyProductFactory.isTransferEnabled(ids[i], from), "TRANSFER_DISABLED");
                unchecked {
                    i++;
                }
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Set the base token URI for all token IDs.
     * @param newuri The new URI to set.
     */
    function setURI(string memory newuri) external onlyRole(GOVERNANCE) {
        _setURI(newuri);
    }

    /**
     * @notice Set the address of the FeyProductFactory contract.
     * @param _feyProductFactory The address of the FeyProductFactory contract.
     */
    function setFeyProductFactory(IFEYFactory _feyProductFactory) external onlyRole(GOVERNANCE) {
        feyProductFactory = _feyProductFactory;
    }

    /**
     * @notice Internal function to set the base token URI for all token IDs.
     * @param newuri The new URI to set.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @notice Returns the base token URI for all token IDs.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev Override function required by ERC-165 to check if a contract implements a given interface.
     * @param interfaceId The ID of the interface to check.
     * @return A boolean indicating whether the contract implements the interface with the given ID.
     */
    function supportsInterface(bytes4 interfaceId) public pure override(StructERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation with _beforeTransfer hook.
/// @author Struct Finance
/// @author Added _beforeTransferHook to Solmate's ERC1155 impl (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract StructERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        _beforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

        for (uint256 i = 0; i < idsLength;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0xd9b67a26 // ERC165 Interface ID for ERC1155
            || interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        _beforeTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < idsLength;) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        _beforeTokenTransfer(msg.sender, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < idsLength;) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        external
        returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// External Imports
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// Internal Imports
import "../../interfaces/IGAC.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title Global Access Control Managed - Base Class
 * @notice Allows inheriting contracts to leverage global access control permissions conveniently, as well as granting contract-specific pausing functionality
 * @dev Inspired from https://github.com/Citadel-DAO/citadel-contracts
 */
contract GACManaged is Pausable {
    IGAC public gac;

    bytes32 internal constant PAUSER = keccak256("PAUSER");
    bytes32 internal constant WHITELISTED = keccak256("WHITELISTED");
    bytes32 internal constant KEEPER = keccak256("KEEPER");
    bytes32 internal constant GOVERNANCE = keccak256("GOVERNANCE");
    bytes32 internal constant MINTER = keccak256("MINTER");
    bytes32 internal constant PRODUCT = keccak256("PRODUCT");
    bytes32 internal constant DISTRIBUTION_MANAGER = keccak256("DISTRIBUTION_MANAGER");
    bytes32 internal constant FACTORY = keccak256("FACTORY");

    /// @dev Initializer
    uint8 private isInitialized;

    /*////////////////////////////////////////////////////////////*/
    /*                           MODIFIERS                        */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @dev only holders of the given role on the GAC can access the methods with this modifier
     * @param role The role that msgSender will be checked against
     */
    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, _msgSender()), Errors.ACE_INVALID_ACCESS);
        _;
    }

    function _gacPausable() private view {
        require(!gac.paused(), Errors.ACE_GLOBAL_PAUSED);
        require(!paused(), Errors.ACE_LOCAL_PAUSED);
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        _gacPausable();
        _;
    }

    /*////////////////////////////////////////////////////////////*/
    /*                           INITIALIZER                      */
    /*////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializer
     * @param _globalAccessControl global access control which is pinged to allow / deny access to permissioned calls by role
     */
    function __GACManaged_init(IGAC _globalAccessControl) public {
        require(isInitialized == 0, Errors.ACE_INITIALIZER);
        isInitialized = 1;
        gac = _globalAccessControl;
    }

    /*////////////////////////////////////////////////////////////*/
    /*                      RESTRICTED ACTIONS                    */
    /*////////////////////////////////////////////////////////////*/

    /// @dev Used to pause certain actions in the contract
    function pause() public onlyRole(PAUSER) {
        _pause();
    }

    /// @dev Used to unpause if paused
    function unpause() public onlyRole(PAUSER) {
        _unpause();
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title The GlobalAccessControl interface
 * @author Struct Finance
 *
 */

interface IGAC {
    /// @notice Used to unpause the contracts globally if it's paused
    function unpause() external;

    /// @notice Used to pause the contracts globally if it's paused
    function pause() external;

    /// @notice Used to grant a specific role to an address
    /// @param role The role to be granted
    /// @param account The address to which the role should be granted
    function grantRole(bytes32 role, address account) external;

    /// @notice Used to validate whether the given address has a specific role
    /// @param role The role to check
    /// @param account The address which should be validated
    /// @return A boolean flag that indicates whether the given address has the required role
    function hasRole(bytes32 role, address account) external view returns (bool);

    /// @notice Used to check if the contracts are paused globally
    /// @return A boolean flag that indicates whether the contracts are paused or not.
    function paused() external view returns (bool);

    /// @notice Used to fetch the roles array `KEEPER_WHITELISTED`
    /// @return An array with the `KEEPER` and `WHITELISTED` roles
    function keeperWhitelistedRoles() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IFEYFactory
 * @notice The interface for the Product factory contract
 * @author Struct Finance
 *
 */

interface IFEYFactory {
    /// @dev Emitted when the product is deployed
    event ProductCreated(
        address indexed productAddress,
        uint256 fixedRate,
        uint256 startTimeDeposit,
        uint256 startTimeTranche,
        uint256 endTimeTranche
    );

    /// @dev Emitted when the tranche is created
    event TrancheCreated(
        address indexed productAddress, DataTypes.Tranche trancheType, address indexed tokenAddress, uint256 capacity
    );

    /// @dev Emitted when a token's status gets updated
    event TokenStatusUpdated(address indexed token, uint256 status);

    /// @dev Emitted when a LP is whitelised
    event PoolStatusUpdated(address indexed lpAddress, uint256 status, address indexed tokenA, address indexed tokenB);

    /// @dev Emitted when the FEYProduct implementaion is updated
    event FEYProductImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);

    /// @dev The following events are emitted when respective setter methods are invoked
    event StructPriceOracleUpdated(address indexed structPriceOracle);
    event TrancheDurationMinUpdated(uint256 minTrancheDuration);
    event TrancheDurationMaxUpdated(uint256 maxTrancheDuration);
    event LeverageThresholdMinUpdated(uint256 levThresholdMin);
    event LeverageThresholdMaxUpdated(uint256 levThresholdMax);
    event TrancheCapacityUpdated(uint256 defaultTrancheCapUSD);
    event PerformanceFeeUpdated(uint256 performanceFee);
    event ManagementFeeUpdated(uint256 managementFee);
    event MinimumInitialDepositValueUpdated(uint256 newValue);
    event MaxFixedRateUpdated(uint256 _fixedRateMax);
    event FactoryGACInitialized(address indexed gac);

    /// @dev Emitted when Yieldsource address is added for a LP token
    event YieldSourceAdded(address indexed lpToken, address indexed yieldSource);

    function createProduct(
        DataTypes.TrancheConfig memory _configTrancheSr,
        DataTypes.TrancheConfig memory _configTrancheJr,
        DataTypes.ProductConfigUserInput memory _productConfigUserInput,
        DataTypes.Tranche _tranche,
        uint256 _initialDepositAmount
    ) external payable;

    function isMintActive(uint256 _spTokenId) external view returns (bool);

    function isTransferEnabled(uint256 _spTokenId, address _user) external view returns (bool);
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
pragma solidity ^0.8.11;

/**
 * @title Errors library [Inspired from AAVE ;)]
 * @notice Defines the error messages emitted by the different contracts of the Struct Finance protocol
 * @dev Error messages prefix glossary:
 *  - VE = Validation Error
 *  - PFE = Price feed Error
 *  - AE = Address Error
 *  - PE = Path Error
 *  - ACE = Access Control Error
 *
 * @author Struct Finance
 */
library Errors {
    string public constant AE_NATIVE_TOKEN = "1";
    /// "Invalid native token address"
    string public constant AE_REWARD1 = "2";
    /// "Invalid Reward 1 token address"
    string public constant AE_REWARD2 = "3";
    /// "Invalid Reward 2 token address"
    string public constant AE_ROUTER = "4";
    /// "Invalid Router token address"
    string public constant PE_SR_TO_JR_1 = "5";
    /// "Invalid Senior token address in Senior to Junior Path"
    string public constant PE_SR_TO_JR_2 = "6";
    /// "Invalid Junior token address in Senior to Junior Path"
    string public constant PE_JR_TO_SR_1 = "7";
    /// "Invalid Junior token address in Junior to Senior Path"
    string public constant PE_JR_TO_SR_2 = "8";
    /// "Invalid Senior token address in Junior to Junior Path"
    string public constant PE_NATIVE_TO_SR_1 = "9";
    /// "Invalid Native token address in Native to Senior Path"
    string public constant PE_NATIVE_TO_SR_2 = "10";
    /// "Invalid Senior token address in Native to Senior Path"
    string public constant PE_NATIVE_TO_JR_1 = "11";
    /// "Invalid Native token address in Native to Junior Path"
    string public constant PE_NATIVE_TO_JR_2 = "12"; //// "Invalid Junior token address in Native to Junior Path"
    string public constant PE_REWARD1_TO_NATIVE_1 = "13";
    /// "Invalid Reward1 token address in Reward1 to Native Path"
    string public constant PE_REWARD1_TO_NATIVE_2 = "14";
    /// "Invalid Native token address in Reward1 to Native Path"
    string public constant PE_REWARD2_TO_NATIVE_1 = "15";
    /// "Invalid Reward2 token address in Reward2 to Native Path"
    string public constant PE_REWARD2_TO_NATIVE_2 = "16";
    /// "Invalid Native token address in Reward2 to Native Path"
    string public constant VE_DEPOSITS_CLOSED = "17"; // `Deposits are closed`
    string public constant VE_DEPOSITS_NOT_STARTED = "18"; // `Deposits are not started yet`
    string public constant VE_AMOUNT_EXCEEDS_CAP = "19"; // `Trying to deposit more than the max capacity of the tranche`
    string public constant VE_INSUFFICIENT_BAL = "20"; // `Insufficient token balance`
    string public constant VE_INSUFFICIENT_ALLOWANCE = "21"; // `Insufficent token allowance`
    string public constant VE_INVALID_STATE = "22";
    /// "Invalid current state for the operation"
    string public constant VE_TRANCHE_NOT_STARTED = "23";
    /// "Tranche is not started yet to add LP"
    string public constant VE_NOT_MATURED = "24";
    /// "Tranche is not matured for removing liquidity from LP"
    string public constant PFE_INVALID_SR_PRICE = "25";
    /// "Senior tranche token price fluctuation is higher or the price is invalid"
    string public constant PFE_INVALID_JR_PRICE = "26";
    /// "Junior tranche token price fluctuation is higher or the price is invalid"
    string public constant VE_ALREADY_CLAIMED = "27";
    /// "Already claimed the excess tokens"
    string public constant VE_NO_EXCESS = "28";
    /// "No excess tokens to claim"
    string public constant ACE_INVALID_ACCESS = "29";
    /// "The caller is not allowed"
    string public constant ACE_HASH_MISMATCH = "30";
    /// "Role string and role do not match"
    string public constant ACE_GLOBAL_PAUSED = "31";
    /// "Interactions paused - protocol-level"
    string public constant ACE_LOCAL_PAUSED = "32";
    /// "Interactions paused - contract-level"
    string public constant ACE_INITIALIZER = "33";
    /// "Contract is initialized more than once"
    string public constant VE_ALREADY_WITHDRAWN = "34";
    /// "User has already withdrawn funds from the tranche"
    string public constant VE_CANNOT_WITHDRAW_YET = "35";
    /// "Cannot withdraw less than 3 weeks from tranche end time"
    string public constant VE_INVALID_LENGTH = "36";
    /// "Invalid swap path length"
    string public constant VE_NOT_CLAIMED_YET = "37";
    /// "The excess are not claimed to withdraw from tranche"
    string public constant VE_NO_FARM = "38";
    /// "There is no farm for the yield farming"

    string public constant VE_INVALID_ALLOCATION = "100";

    /// "Allocation cannot be zero"
    string public constant VE_INVALID_DISTRIBUTION_TOKEN = "101";
    /// "Invalid Struct token distribution amount"
    string public constant VE_DISTRIBUTION_NOT_STARTED = "103";
    /// "Distribution not started"
    string public constant VE_INVALID_INDEX = "105";
    /// "Invalid index"
    string public constant VE_NO_RECIPIENTS = "106";
    /// "Must have recipients to distribute to"
    string public constant VE_INVALID_REWARD_RATE = "107";
    /// "Reward rate too high"
    string public constant AE_ZERO_ADDRESS = "108";
    /// "Address cannot be a zero address"
    string public constant VE_NO_WITHDRAW_OR_EXCESS = "109";
    /// User must have an excess and/or withdrawal to claim
    string public constant VE_INVALID_DISTRIBUTION_FEE = "110";
    /// "Invalid native token distribution amount"

    string public constant VE_INVALID_TRANCHE_CAP = "200";

    /// "Invalid min capacity for the given tranche"
    string public constant VE_INVALID_STATUS = "202";
    /// "Invalid status arg. The status should be either 1 or 2"
    string public constant VE_INVALID_POOL = "203";
    /// "Pool doesn't exist"
    string public constant VE_TRANCHE_CAPS_EXCEEDS_DEVIATION = "204";
    /// "Tranche caps exceed MAX_DEVIATION"
    string public constant VE_TOKEN_INACTIVE = "205";
    /// "Token is not active"
    string public constant VE_EXCEEDS_TRANCHE_MAXCAP = "206";
    /// "Given tranche capacity is more than the allowed max cap"
    string public constant VE_BELOW_TRANCHE_MINCAP = "207";
    ///  "Given tranche capacity is less than the allowed min cap"
    string public constant VE_INVALID_RATE = "209";
    ///  "Fixed rate is more than the threshold or equal to zero"
    string public constant VE_INVALID_DEPOSIT_START_TIME = "210";
    ///  "Deposit start time is not a future timestamp"
    string public constant VE_INVALID_TRANCHE_START_TIME = "211";
    ///  "Tranche start time is not greater than the deposit start time"
    string public constant VE_INVALID_TRANCHE_END_TIME = "212";
    ///  "Tranche end time is not greater than the tranche start time"
    string public constant VE_INVALID_TRANCHE_DURATION = "213";
    ///  "Tranche duration is not greater than the minimum duration specified"
    string public constant VE_INVALID_LEV_MIN = "214";
    ///  "Invalid Leverage threshold min"
    string public constant VE_INVALID_LEV_MAX = "215";
    ///  "Invalid Leverage threshold max"
    string public constant VE_INVALID_FARM = "217";
    ///  "Invalid Farm (PoolId)"
    string public constant VE_INVALID_SLIPPAGE = "218";
    ///  "Slippage exceeds limit"
    string public constant VE_LEV_MAX_GT_LEV_MIN = "219";
    ///  "Invalid leverage threshold limits (levMax must be > levMax)"
    string public constant VE_INVALID_TRANSFER_AMOUNT = "220";
    ///  "Amount received is less than mentioned"
    string public constant VE_MIN_DEPOSIT_VALUE = "221";
    ///  "Minimum deposit value is not > 0 and < trancheCapacityUSD"
    string public constant VE_INVALID_YS_INPUTS = "222";
    ///  "Length of LP tokens array and yield sources array are not the same"
    string public constant VE_INVALID_INPUT_AMOUNT = "223";
    /// "Input amount is not equal to msg.value"
    string public constant VE_INVALID_TOKEN = "224";
    /// "Token cannot be zero address"
    string public constant VE_INVALID_YS_ADDRESS = "225";
    ///  "LP token and yield source cannot be zero addresses"
    string public constant VE_INVALID_ZERO_ADDRESS = "226"; // New address cannot be set to zero address
    string public constant VE_INVALID_ZERO_VALUE = "227"; // New value cannot be set to zero
    string public constant VE_INVALID_LEV_THRESH_MAX = "228"; // New leverageThresholdMaxCap value cannot be greater than leverageThresholdMinCap
    string public constant VE_INVALID_LEV_THRESH_MIN = "229"; // // New leverageThresholdMinCap value cannot be less than leverageThresholdMaxCap
    string public constant AVAX_TRANSFER_FAILED = "230";
    /// "Failed to transfer AVAX"
    string public constant VE_YIELD_SOURCE_ALREADY_SET = "231";
    /// "Yield source already set on Factory"
    string public constant VE_INVALID_TRANCHE_DURATION_MAX = "232";
    ///  "Tranche duration max is lesser than tranche duration min"
    string public constant VE_INVALID_NATIVE_TOKEN_DEPOSIT = "233";
    /// "Native token deposit is not allowed for non-wAVAX tranches"
    string public constant VE_INVALID_TRANCHE_DURATION_MIN = "234";
    ///  "Tranche duration min is greater than tranche duration max"
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// External Imports
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// Internal Imports
import "../../../external/traderjoe/IJoeRouter.sol";
import "../../../external/traderjoe/IJoePair.sol";
import "../../../external/traderjoe/IMasterChef.sol";

library DataTypes {
    /// @notice It contains the details of the tranche
    struct TrancheInfo {
        /// Actual deposits of the users (aggregate) that are being queued
        uint256 tokensDeposited;
        /// Number of tokens that are eligible for investment into a pool per tranche
        uint256 tokensInvestable;
        /// Tokens that cannot be tokensInvested
        uint256 tokensExcess;
        /// Tokens invested into AMM
        uint256 tokensInvested;
        /// Tracks the tokens available on maturity
        uint256 tokensAtMaturity;
        /// Tracks the tokens received from the AMM's liquidity pool
        uint256 tokensReceivedFromLP;
    }

    /// @notice It contains the configuration of the tranche
    /// @dev It is populated during product creation
    struct TrancheConfig {
        /// Contract address of the tranche token
        IERC20Metadata tokenAddress;
        /// Tranche Token decimals
        uint256 decimals;
        /// Token ID of StructSP tokens for the tranche
        uint256 spTokenId;
        /// Maximum tokens that can be deposited
        uint256 capacity;
    }

    /// @notice It contains the general configuration of the product
    /// @dev It is populated during product creation
    struct ProductConfig {
        /// ID of the pool (for recompunding)
        uint256 poolId;
        /// Interest rate
        uint256 fixedRate;
        /// The timestamp after which users can deposit tokens into the tranches.
        uint256 startTimeDeposit;
        /// The start timestamp of the tranche.
        uint256 startTimeTranche;
        /// The end timestamp of the tranche (Maturity).
        uint256 endTimeTranche;
        ///  The minimum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMin;
        ///  The maximum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMax;
        /// The management fee %
        uint256 managementFee;
        /// The performance fee %
        uint256 performanceFee;
    }

    /// @notice It contains the properties of the product configuration set by the user
    /// @dev The properties are reassigned to ProductConfig during product creation
    struct ProductConfigUserInput {
        /// Interest rate
        uint256 fixedRate;
        /// The start timestamp of the tranche.
        uint256 startTimeTranche;
        /// The end timestamp of the tranche (Maturity).
        uint256 endTimeTranche;
        ///  The minimum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMin;
        ///  The maximum ratio required for deposit to be tokensInvested
        uint256 leverageThresholdMax;
    }

    /**
     * @notice
     *  OPEN - Product contract has been created, and still open for deposits
     *  INVESTED - Funds has been deposited into LP
     *  WITHDRAWN -  Funds have been withdrawn from LP
     */
    enum State {
        OPEN,
        INVESTED,
        WITHDRAWN
    }

    enum Tranche {
        Senior,
        Junior
    }

    /// @notice Struct used to store the details of the investor
    /// @dev Inspired by Ondo Finance
    struct Investor {
        uint256[] userSums;
        uint256[] depositSums;
        uint256 spTokensStaked;
        bool claimed;
        bool depositedNative;
    }

    /// @notice Struct of arrays containing all the routes for swap
    struct SwapPath {
        address[] seniorToJunior;
        address[] juniorToSenior;
        address[] nativeToSenior;
        address[] nativeToJunior;
        address[] seniorToNative;
        address[] juniorToNative;
        address[] reward1ToNative;
        address[] reward2ToNative;
    }

    /// @notice It contains all the contract addresses for interaction
    struct Addresses {
        IERC20Metadata nativeToken;
        IERC20Metadata reward1;
        IERC20Metadata reward2;
        IJoePair lpToken;
        IMasterChef masterChef;
        IJoeRouter router;
    }

    // amount: amount of Struct tokens that are currently locked
    // end: epoch time that the lock expires (doesn't seem to be in epoch units, but the time of the final epoch)
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    // Contains tranche config to prevent stack too deep
    struct InitConfigParam {
        DataTypes.TrancheConfig configTrancheSr;
        DataTypes.TrancheConfig configTrancheJr;
        DataTypes.ProductConfig productConfig;
    }

    /// @notice The struct contains the product info for the FEYGMXProducts
    /// @custom: tokenA Address of the tokenA
    /// @custom: tokenB Address of tokenB
    /// @custom: tokenADecimals Decimals of tokenA
    /// @custom: tokenBDecimals Decimals of tokenB
    /// @custom: fsGLPReceived The amount of fsGLPReceived
    /// @custom: shares The shares of the product
    /// @custom: sameToken Whether the tokens are the same
    struct FEYGMXProductInfo {
        address tokenA;
        uint8 tokenADecimals;
        address tokenB;
        uint8 tokenBDecimals;
        uint256 fsGLPReceived;
        uint256 shares;
        bool sameToken;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IJoeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

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

    function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

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

    function swapAVAXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJoePair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function getReserves() external view returns (uint112, uint112, uint32);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMasterChef {
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOE to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that JOE distribution occurs.
        uint256 accJoePerShare; // Accumulated JOE per share, times 1e12. See below.
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256, address, string memory, uint256);

    function poolLength() external view returns (uint256);

    function rewarderBonusTokenInfo(uint256 _pid) external view returns (address, string memory);
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