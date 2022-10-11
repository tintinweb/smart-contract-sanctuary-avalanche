// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "../shared/WithRegistry.sol";
// import "../shared/CoreController.sol";
import "@etherisc/gif-interface/contracts/modules/ILicense.sol";

import "@openzeppelin/contracts/utils/Context.sol";

contract ProductService is
    WithRegistry,
    // CoreController
    Context
 {
    bytes32 public constant NAME = "ProductService";

    // solhint-disable-next-line no-empty-blocks
    constructor(address _registry) WithRegistry(_registry) {}

    fallback() external {
        // getAuthorizationStatus enforces msg.sender to be a registered product
        (,bool isAuthorized, address policyFlow) = _license().getAuthorizationStatus(_msgSender());

        require(isAuthorized, "ERROR:PRS-001:NOT_AUTHORIZED");
        require(policyFlow != address(0),"ERROR:PRS-002:POLICY_FLOW_NOT_RESOLVED");

        _delegate(policyFlow);
    }


    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     * This function is a 1:1 copy of _delegate from
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.6/contracts/proxy/Proxy.sol
     */
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _license() internal view returns (ILicense) {
        return ILicense(registry.getContract("License"));
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface ILicense {

    function getAuthorizationStatus(address _sender)
        external
        view
        returns (uint256 productId, bool isAuthorized, address policyFlow);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "@etherisc/gif-interface/contracts/modules/IRegistry.sol";

contract WithRegistry {

/*
 *  We can consider the registry address as immutable here as it contains the
 *  root data structure for the whole GIF Instance.
 *  We can therefore ensure that a policy flow cannot overwrite the address
 *  neither by chance nor by intention.
 */
    IRegistry public immutable registry;

    modifier onlyInstanceOperator() {
        require(
            msg.sender == getContractFromRegistry("InstanceOperatorService"),
            "ERROR:ACM-001:NOT_INSTANCE_OPERATOR"
        );
        _;
    }

    modifier onlyOracleService() {
        require(
            msg.sender == getContractFromRegistry("OracleService"),
            "ERROR:ACM-004:NOT_ORACLE_SERVICE"
        );
        _;
    }

    modifier onlyOracleOwner() {
        require(
            msg.sender == getContractFromRegistry("OracleOwnerService"),
            "ERROR:ACM-005:NOT_ORACLE_OWNER"
        );
        _;
    }

    modifier onlyProductOwner() {
        require(
            msg.sender == getContractFromRegistry("ProductOwnerService"),
            "ERROR:ACM-006:NOT_PRODUCT_OWNER"
        );
        _;
    }

    constructor(address _registry) {
        registry = IRegistry(_registry);
    }

    function getContractFromRegistry(bytes32 _contractName)
        public
        // override
        view
        returns (address _addr)
    {
        _addr = registry.getContract(_contractName);
    }

    function getContractInReleaseFromRegistry(bytes32 _release, bytes32 _contractName)
        internal
        view
        returns (address _addr)
    {
        _addr = registry.getContractInRelease(_release, _contractName);
    }

    function getReleaseFromRegistry() internal view returns (bytes32 _release) {
        _release = registry.getRelease();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);

    function contracts() external view returns (uint256 _numberOfContracts);

    function contractName(uint256 idx) external view returns (bytes32 _contractName);

}