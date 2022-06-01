/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-31
*/

// File: contracts/interfaces/ITreasury.sol


pragma solidity >=0.8.14;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function assetValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (int256);

    function baseSupply() external view returns (uint256);
}

// File: contracts/interfaces/IAssetPricer.sol


pragma solidity ^0.8.14;

interface IAssetPricer {
    function valuation(
        address _asset,
        address _quote,
        uint256 _amount
    ) external view returns (uint256);
}

// File: contracts/interfaces/IDiamondCut.sol


pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// File: contracts/libraries/LibDiamond.sol


pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/


// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// File: contracts/interfaces/ICreditREQ.sol


pragma solidity >=0.8.14;

interface ICreditREQ {
  function changeDebt(
    uint256 amount,
    address debtor,
    bool add
  ) external;

  function debtBalances(address _address) external view returns (uint256);
}

// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/IERC20Metadata.sol



pragma solidity ^0.8.14;


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
// File: contracts/utils/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.14;


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
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      "SAFE_ERC20_CALL_FAILED"
    );
  }
}

// File: contracts/interfaces/IREQ.sol


pragma solidity >=0.7.5;


interface IREQ is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// File: contracts/libraries/LibStorage.sol


pragma solidity ^0.8.14;




// We do ot use an array of stucts to avoid pointer conflicts
// Mappings help us avoid out of bound issues as in arrays,
// particularly if another mapping is added to the struct
struct QueueStorage {
    uint256 currentIndex;
    mapping(uint256 => uint256) managing;
    mapping(uint256 => address) toPermit;
    mapping(uint256 => address) calculator;
    mapping(uint256 => uint256) timelockEnd;
    mapping(uint256 => bool) nullify;
    mapping(uint256 => bool) executed;
    mapping(uint256 => address) quote;
}


// Management storage that stores the different DAO roles
struct ManagementStorage {
    address governor;
    address guardian;
    address policy;
    address vault;
    address newGovernor;
    address newGuardian;
    address newPolicy;
    address newVault;
}

// The core Treasury store
struct TreasuryStorage {
    // requiem global assets
    IREQ REQ;
    ICreditREQ CREQ;
    // general registers
    mapping(uint256 => address[]) registry;
    mapping(uint256 => mapping(address => bool)) permissions;
    mapping(address => address) assetPricer;
    mapping(address => uint256) debtLimits;
    // asset data
    mapping(address => uint256) assetReserves;
    mapping(address => uint256) assetDebt;
    // aggregted data
    uint256 totalReserves;
    uint256 totalDebt;
    uint256 reqDebt;
    
    uint256 timeNeededForQueue;
    bool timelockEnabled;
    bool useExcessReserves;
    uint256 onChainGovernanceTimelock;
    mapping(address => address) quotes;
}

/**
 * All of Requiems's treasury storage is stored in a single TreasuryStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "requiem.treasury.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.treasuryStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.treasuryStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant TREASURY_STORAGE = keccak256("requiem.storage.treasury");
    bytes32 constant QUEUE_STORAGE = keccak256("requiem.storage.queue");
    bytes32 constant MANAGEMENT_STORAGE = keccak256("requiem.storage.authority");

    function treasuryStorage() internal pure returns (TreasuryStorage storage ts) {
        bytes32 position = TREASURY_STORAGE;
        assembly {
            ts.slot := position
        }
    }

    function queueStorage() internal pure returns (QueueStorage storage qs) {
        bytes32 position = QUEUE_STORAGE;
        assembly {
            qs.slot := position
        }
    }

    function managementStorage() internal pure returns (ManagementStorage storage ms) {
        bytes32 position = MANAGEMENT_STORAGE;
        assembly {
            ms.slot := position
        }
    }

    // Authority access control
    function enforcePolicy() internal view {
        require(msg.sender == managementStorage().policy, "Treasury: Must be policy");
    }

    function enforceGovernor() internal view {
        require(msg.sender == managementStorage().governor, "Treasury: Must be governor");
    }

    function enforceGuardian() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be guardian");
    }

    function enforceVault() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be vault");
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function ts() internal pure returns (TreasuryStorage storage) {
        return LibStorage.treasuryStorage();
    }

    function qs() internal pure returns (QueueStorage storage) {
        return LibStorage.queueStorage();
    }

    function ms() internal pure returns (ManagementStorage storage) {
        return LibStorage.managementStorage();
    }
}

// File: contracts/facets/TreasuryFacet.sol


pragma solidity ^0.8.14;








// the managing / status input is coded as follows:
// enum STATUS {
//     ASSETDEPOSITOR, = 0
//     ASSET, = 1
//     ASSETMANAGER, = 2
//     REWARDMANAGER, = 3
//     DEBTMANAGER, = 4
//     DEBTOR, = 5
//     COLLATERAL, = 6
//     CREQ = 7
// }

// Local Queue struct outside of LibStorage to keep upgradeability
// The managing field uses the indexing according to the commented enum above
// We use uint256 as enums are not upgradeable.
struct Queue {
    uint256 managing;
    address toPermit;
    address calculator;
    uint256 timelockEnd;
    bool nullify;
    bool executed;
    address quote;
}

// Helper library to enable upgradeable queuing
// It just uses the current state of the queue storage and parses it to
// the Queue struct above - which avoids using arrays or mappings of structs
// Gas cost is not too important here as these are only used in rare cases
library QueueStorageLib {
    function push(QueueStorage storage self, Queue memory newEntry) internal {
        uint256 newIndex = self.currentIndex + 1;
        self.currentIndex = newIndex;
        self.managing[newIndex] = newEntry.managing;
        self.toPermit[newIndex] = newEntry.toPermit;
        self.calculator[newIndex] = newEntry.calculator;
        self.timelockEnd[newIndex] = newEntry.timelockEnd;
        self.nullify[newIndex] = newEntry.nullify;
        self.executed[newIndex] = newEntry.executed;
    }

    function get(QueueStorage storage self, uint256 _index) internal view returns (Queue memory) {
        require(_index <= self.currentIndex && _index > 0, "Queue: Invalid index");
        return
            Queue(
                self.managing[_index],
                self.toPermit[_index],
                self.calculator[_index],
                self.timelockEnd[_index],
                self.nullify[_index],
                self.executed[_index],
                self.quote[_index]
            );
    }
}

// The treasury facet that contains the logic that changes the storage
// Aligned with EIP-2535, the contract has no constructor or an own state
contract TreasuryFacet is ITreasury, WithStorage {
    using SafeERC20 for IERC20;
    using QueueStorageLib for QueueStorage;

    /* ========== EVENTS ========== */
    event Deposit(address indexed asset, uint256 amount, uint256 value);
    event Withdrawal(address indexed asset, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed asset, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed asset, uint256 amount, uint256 value);
    event Managed(address indexed asset, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(uint256 indexed status, address queued);
    event Permissioned(address addr, uint256 indexed status, bool result);

    // administrative
    modifier onlyGovernor() {
        LibStorage.enforceGovernor();
        _;
    }

    modifier onlyPolicy() {
        LibStorage.enforcePolicy();
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for ts().REQ
     * @param _amount uint256
     * @param _asset address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _asset,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (ts().permissions[1][_asset]) {
            require(ts().permissions[0][msg.sender], "Treasury: not approved");
        } else {
            revert("Treasury: invalid asset");
        }

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = assetValue(_asset, _amount);
        // mint needed and store amount of rewards for distribution
        send_ = value - _profit;
        ts().REQ.mint(msg.sender, send_);

        ts().totalReserves += value;

        emit Deposit(_asset, _amount, value);
    }

    /**
     * @notice allow approved address to burn REQ for reserves
     * @param _amount uint256
     * @param _asset address
     */
    function withdraw(uint256 _amount, address _asset) external override {
        require(ts().permissions[1][_asset], "Treasury: not accepted");
        require(ts().permissions[2][msg.sender], "Treasury: not approved");

        uint256 value = assetValue(_asset, _amount);
        ts().REQ.burnFrom(msg.sender, value);

        ts().totalReserves -= value;

        IERC20(_asset).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_asset, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _asset address
     * @param _amount uint256
     */
    function manage(address _asset, uint256 _amount) external override {
        require(ts().permissions[2][msg.sender], "Treasury: not approved");

        if (ts().permissions[1][_asset]) {
            uint256 value = assetValue(_asset, _amount);
            if (ts().useExcessReserves) require(int256(value) <= excessReserves(), "Treasury: insufficient reserves");

            ts().totalReserves -= value;
        }
        IERC20(_asset).safeTransfer(msg.sender, _amount);
        emit Managed(_asset, _amount);
    }

    /**
     * @notice mint new ts().REQ using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(ts().permissions[3][msg.sender], "Treasury: not approved");
        if (ts().useExcessReserves) require(int256(_amount) <= excessReserves(), "Treasury: insufficient reserves");

        ts().REQ.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or REQ from the treasury, using CREQ as collateral. This might allow an
     * CREQ holder to provide REQ liquidity without taking on the opportunity cost
     * of unstaking, or alter their backing without imposing risk onto the treasury.
     * Many of these use cases are yet to be defined, but they appear promising.
     * However, we urge the community to think critically and move slowly upon
     * proposals to acquire these permissions.
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _asset address
     */
    function incurDebt(uint256 _amount, address _asset) external override {
        uint256 value;
        require(ts().permissions[5][msg.sender], "Treasury: not approved");

        if (_asset == address(ts().REQ)) {
            value = _amount;
        } else {
            value = assetValue(_asset, _amount);
        }
        require(value != 0, "Treasury: invalid asset");

        ts().CREQ.changeDebt(value, msg.sender, true);
        require(ts().CREQ.debtBalances(msg.sender) <= ts().debtLimits[msg.sender], "Treasury: exceeds limit");
        ts().totalDebt += value;

        if (_asset == address(ts().REQ)) {
            ts().REQ.mint(msg.sender, value);
            ts().reqDebt += value;
        } else {
            ts().totalReserves -= value;
            IERC20(_asset).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _asset, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _asset address
     */
    function repayDebtWithReserve(uint256 _amount, address _asset) external override {
        require(ts().permissions[5][msg.sender], "Treasury: not approved");
        require(ts().permissions[1][_asset], "Treasury: not accepted");
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = assetValue(_asset, _amount);
        ts().CREQ.changeDebt(value, msg.sender, false);
        ts().totalDebt -= value;
        ts().totalReserves += value;
        emit RepayDebt(msg.sender, _asset, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with REQ
     * @param _amount uint256
     */
    function repayDebtWithREQ(uint256 _amount) external {
        require(ts().permissions[5][msg.sender], "Treasury: not approved");
        ts().REQ.burnFrom(msg.sender, _amount);
        ts().CREQ.changeDebt(_amount, msg.sender, false);
        ts().totalDebt -= _amount;
        ts().reqDebt -= _amount;
        emit RepayDebt(msg.sender, address(ts().REQ), _amount, _amount);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory assets = ts().registry[1];
        for (uint256 i = 0; i < assets.length; i++) {
            if (ts().permissions[1][assets[i]]) {
                reserves += assetValue(assets[i], IERC20(assets[i]).balanceOf(address(this)));
            }
        }
        ts().totalReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        ts().debtLimits[_address] = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _pricer address
     */
    function enable(
        uint256 _status,
        address _address,
        address _pricer
    ) external {
        require(!ts().timelockEnabled, "Use queueTimelock");
        if (_status == 7) {
            ts().CREQ = ICreditREQ(_address);
        } else {
            ts().permissions[_status][_address] = true;

            if (_status == 1) {
                ts().assetPricer[_address] = _pricer;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                ts().registry[_status].push(_address);

                if (_status == 1) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete ts().registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(uint256 _status, address _toDisable) external {
        require(msg.sender == ms().governor || msg.sender == ms().guardian, "Only governor or guardian");
        ts().permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if ts().registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, uint256 _status) public view returns (bool, uint256) {
        address[] memory entries = ts().registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice changes the use of excess reserves for minting
     */
    function setUseExcessReserves() external {
        ts().useExcessReserves = !ts().useExcessReserves;
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _pricer address
     * @param _quote address
     */
    function queueTimelock(
        uint256 _status,
        address _address,
        address _pricer,
        address _quote
    ) external onlyGovernor {
        require(_address != address(0));
        require(ts().timelockEnabled, "Timelock is disabled, use enable");
        uint256 timelock = block.timestamp + ts().timeNeededForQueue;
        if (_status == 2) {
            timelock = block.timestamp + ts().timeNeededForQueue * 2;
        }
        if (_pricer != address(0)) {
            require(_quote != address(0), "Must provide quote");
        }

        qs().push(
            Queue({
                managing: _status,
                toPermit: _address,
                calculator: _pricer,
                timelockEnd: timelock,
                nullify: false,
                executed: false,
                quote: _quote
            })
        );
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(ts().timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = qs().get(_index);

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.timestamp >= info.timelockEnd, "Timelock not complete");

        if (info.managing == 7) {
            ts().CREQ = ICreditREQ(info.toPermit);
        } else {
            ts().permissions[info.managing][info.toPermit] = true;

            if (info.managing == 1) {
                ts().assetPricer[info.toPermit] = info.calculator;
                ts().quotes[info.toPermit] = info.quote;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                ts().registry[info.managing].push(info.toPermit);

                if (info.managing == 1) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, 1);
                    if (reg) {
                        delete ts().registry[1][index];
                    }
                }
            }
        }
        qs().executed[_index] = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        qs().nullify[_index] = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(ts().timelockEnabled, "timelock already disabled");
        if (ts().onChainGovernanceTimelock != 0 && ts().onChainGovernanceTimelock <= block.timestamp) {
            ts().timelockEnabled = false;
        } else {
            ts().onChainGovernanceTimelock = block.timestamp + ts().timeNeededForQueue * 7; // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function enableTimelock(uint256 _timeNeededForQueue) external onlyGovernor {
        require(!ts().timelockEnabled, "timelock already enabled");
        ts().timelockEnabled = true;
        ts().timeNeededForQueue = _timeNeededForQueue;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns excess reserves not backing assets
     * @return int
     */
    function excessReserves() public view returns (int256) {
        return int256(ts().totalReserves) - int256(ts().REQ.totalSupply() - ts().totalDebt);
    }

    /**
     * @notice returns REQ valuation of asset
     * @param _asset address
     * @param _amount uint256
     * @return value_ uint256
     */
    function assetValue(address _asset, uint256 _amount) public view override returns (uint256 value_) {
        if (ts().permissions[1][_asset]) {
            value_ = IAssetPricer(ts().assetPricer[_asset]).valuation(_asset, ts().quotes[_asset], _amount);
        } else {
            revert("Treasury: invalid asset");
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return ts().REQ.totalSupply() - ts().reqDebt;
    }

    // VIEWS FROM STORAGE

    function assetPricer(address _entry) external view returns (address) {
        return ts().assetPricer[_entry];
    }

    function registry(uint256 _status, uint256 _entry) external view returns (address) {
        return ts().registry[_status][_entry];
    }

    function permissions(uint256 _status, address _entry) external view returns (bool) {
        return ts().permissions[_status][_entry];
    }

    function debtLimits(address _asset) public view returns (uint256) {
        return ts().debtLimits[_asset];
    }

    function assetReserves(address _asset) public view returns (uint256) {
        return ts().assetReserves[_asset];
    }

    function totalReserves() public view returns (uint256) {
        return ts().totalReserves;
    }

    function totalDebt() public view returns (uint256) {
        return ts().totalDebt;
    }

    function permissionQueue(uint256 _index) public view returns (Queue memory) {
        return qs().get(_index);
    }

    function timelockEnabled() public view returns (bool) {
        return ts().timelockEnabled;
    }

    function useExcessReserves() public view returns (bool) {
        return ts().useExcessReserves;
    }

    function onChainGovernanceTimelock() public view returns (uint256) {
        return ts().onChainGovernanceTimelock;
    }

    function REQ() public view returns (IREQ) {
        return ts().REQ;
    }

    function CCREQ() public view returns (ICreditREQ) {
        return ts().CREQ;
    }
}