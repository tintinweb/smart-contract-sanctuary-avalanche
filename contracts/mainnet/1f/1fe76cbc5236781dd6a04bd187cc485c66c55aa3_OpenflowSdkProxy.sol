// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IOpenflowFactory} from "../interfaces/IOpenflow.sol";
import {OpenflowProxy} from "../sdk/OpenflowProxy.sol";

/// @title OpenflowSdkProxy
/// @author Openflow
/// @dev Each SDK instance gets its own proxy contract
/// @dev Only instance owner can update implementation
/// @dev Implementation can be updated from official SDK releases (from factory)
/// or alternatively user can provide their own SDK implementation
contract OpenflowSdkProxy is OpenflowProxy {
    bytes32 constant _FACTORY_SLOT =
        0xbc0b033692987f57b00e59fb320fa52dee8008f8dd89a9404b16c6c70befc06d; // keccak256('openflow.sdk.factory')
    bytes32 constant _VERSION_SLOT =
        0xd9b5749cb01e4e7fad114e8dee44b84863de878d17f808275ae4b45e0620d128; // keccak256('openflow.sdk.version')

    /// @notice Initialize proxy.
    constructor(
        address _implementationAddress,
        address _ownerAddress
    ) OpenflowProxy(_implementationAddress, _ownerAddress) {
        uint256 currentVersion = IOpenflowFactory(msg.sender).currentVersion();
        assembly {
            sstore(_FACTORY_SLOT, caller())
            sstore(_VERSION_SLOT, currentVersion)
        }
    }

    /// @notice Fetch current factory address.
    function factory() public view returns (address _factoryAddress) {
        assembly {
            _factoryAddress := sload(_FACTORY_SLOT)
        }
    }

    /// @notice Fetch current implementation version.
    function implementationVersion() public view returns (uint256 _version) {
        assembly {
            _version := sload(_VERSION_SLOT)
        }
    }

    /// @notice Update to the latest SDK version.
    /// @dev SDK version comes from factory.
    /// @dev Only proxy owner can update version.
    function updateSdkVersion() external {
        uint256 currentVersion = IOpenflowFactory(factory()).currentVersion();
        updateSdkVersion(currentVersion);
    }

    /// @notice Update version to a specific factory SDK version
    /// @dev Also supports downgrades.
    /// @dev Only proxy owner can update version.
    /// @param version Version to update to.
    function updateSdkVersion(uint256 version) public {
        require(msg.sender == owner(), "Only owner can update SDK version");
        assembly {
            sstore(_VERSION_SLOT, version)
        }
        uint256 currentVersion = IOpenflowFactory(factory()).currentVersion();
        require(version <= currentVersion && version != 0, "Invalid version");
        address implementation = IOpenflowFactory(factory())
            .implementationByVersion(version);
        _updateImplementation(implementation);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOpenflowSdk {
    struct Options {
        /// @dev Driver is responsible for authenticating quote selection.
        /// If no driver is set anyone with the signature will be allowed
        /// to execute the signed payload. Driver is user-configurable
        /// which means the end user does not have to trust Openflow driver
        /// multisig. If the user desires, the user can run their own
        /// decentralized multisig driver.
        address driver;
        /// @dev Oracle is responsible for determining minimum amount out for an order.
        /// If no oracle is provided the default Openflow oracle will be used.
        address oracle;
        /// @dev If true calls will revert if oracle is not able to find an appropriate price.
        bool requireOracle;
        /// @dev Acceptable slippage threshold denoted in BIPs.
        uint256 slippageBips;
        /// @dev Maximum duration for auction. The order is invalid after the auction ends.
        uint256 auctionDuration;
        /// @dev Manager is responsible for managing SDK options.
        address manager;
        /// @dev If true manager is allowed to perform swaps on behalf of the
        /// instance initiator (sender).
        bool managerCanSwap;
        /// @dev Funds will be sent to recipient after swap.
        address recipient;
    }

    function swap(
        address fromToken,
        address toToken
    ) external returns (bytes memory orderUid);

    function options() external view returns (Options memory options);

    function setOptions(Options memory options) external;

    function initialize(
        address settlement,
        address manager,
        address recipient
    ) external;

    function updateSdkVersion() external;

    function updateSdkVersion(uint256 version) external;
}

interface IOpenflowFactory {
    function newSdkInstance() external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager
    ) external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager,
        address sender,
        address recipient
    ) external returns (IOpenflowSdk sdkInstance);

    function implementationByVersion(
        uint256 version
    ) external view returns (address implementation);

    function currentVersion() external view returns (uint256 version);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// @title OpenflowProxy
/// @author Openflow
/// @notice Minimal upgradeable EIP-1967 proxy
/// @dev We use a minimal EIP-1976 version (same codebase as battle tested 0xDAO proxy)
/// instead of OpenZeppelin implementation because the logic is lightweight/simple and
/// OpenZeppelin implementation is bloated and complex.
contract OpenflowProxy {
    /// @dev Only hashed storage slots are used. This is to prevent any potential storage slot collisions.
    bytes32 constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
    bytes32 constant _OWNER_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

    /// @notice Initialize proxy.
    constructor(address _implementationAddress, address _ownerAddress) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _implementationAddress)
            sstore(_OWNER_SLOT, _ownerAddress)
        }
    }

    /// @notice Fetch current implementation address.
    function implementationAddress()
        external
        view
        returns (address _implementationAddress)
    {
        assembly {
            _implementationAddress := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @notice Fetch current proxy owner address.
    function owner() public view returns (address _ownerAddress) {
        assembly {
            _ownerAddress := sload(_OWNER_SLOT)
        }
    }

    /// @notice Update implementation to a user defined implementation.
    /// @dev Only proxy owner can update implementation.
    /// @dev Warning: user must be careful to avoid storage slot collisions.
    /// @dev Use at your own risk.
    /// @param _implementation Implementation address to upgrade to.
    function updateImplementation(address _implementation) external {
        require(msg.sender == owner(), "Only owner can update implementation");
        _updateImplementation(_implementation);
    }

    /// @notice Internal method for updating implementation
    /// @param _implementation Implementation address to upgrade to.
    function _updateImplementation(address _implementation) internal {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _implementation)
        }
    }

    /// @notice Update proxy owner.
    /// @dev Only current owner can update owner.
    function updateOwner(address _owner) external {
        require(msg.sender == owner(), "Only owners can update owners");
        assembly {
            sstore(_OWNER_SLOT, _owner)
        }
    }

    /// @notice Fallback to delegate method calls to current implementation.
    /// @dev Code comes from Gnosis Safe.
    fallback() external {
        assembly {
            let contractLogic := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}