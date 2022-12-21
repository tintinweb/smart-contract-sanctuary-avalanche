// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Upgradeable.sol";

contract SoulWalletLogicTestBefore is Upgradeable {
    bool initialized;
    address public owner;
    address allowedImplementation;

    uint256[50] __gap;

    constructor() {
        // disable constructor
    }

    function initialize(address owner_) external {
        require(!initialized, "already initialized");
        owner = owner_;
        initialized = true;
    }

    function setAllowedUpgrade(address implementation) external {
        require(msg.sender == owner, "only owner");
        require(implementation != address(0), "invalid implementation");
        allowedImplementation = implementation;
    }

    function upgradeVerifiy(address implementation) private {
        require(msg.sender == owner, "only owner can upgrade");
        require(
            implementation == allowedImplementation,
            "invalid implementation"
        );
        allowedImplementation = address(0);
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external payable {
        upgradeVerifiy(newImplementation);
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
    {
        upgradeVerifiy(newImplementation);
        _upgradeToAndCall(newImplementation, data);
    }

    function getLogicInfo() external pure returns (string memory) {
        return "SoulWalletLogicTestBefore";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Address.sol";

abstract contract Upgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The `Upgraded` event signature is given by:
    // `keccak256(bytes("Upgraded(address)"))`.
    bytes32 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation()
        internal
        view
        returns (address implementation)
    {
        assembly {
            implementation := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation));
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementationUnsafe(address newImplementation) private {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        assembly {
            // emit Upgraded(newImplementation);
            let _newImplementation := and(newImplementation, _BITMASK_ADDRESS)
            // Emit the `Upgraded` event.
            log2(0, 0, _UPGRADED_EVENT_SIGNATURE, _newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToUnsafe(address newImplementation) internal {
        _setImplementationUnsafe(newImplementation);
        assembly {
            // emit Upgraded(newImplementation);
            let _newImplementation := and(newImplementation, _BITMASK_ADDRESS)
            // Emit the `Upgraded` event.
            log2(0, 0, _UPGRADED_EVENT_SIGNATURE, _newImplementation)
        }
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data)
        internal
    {
        _upgradeTo(newImplementation);
        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    function _initialize(address newImplementation, bytes memory data)
        internal
    {
        _upgradeToUnsafe(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }
}

// SPDX-License-Identifier: MIT
// from OpenZeppelin Contracts::`utils/Address.sol`

pragma solidity ^0.8.17;

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

        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal {
        require(isContract(target));
        assembly {
            let result := delegatecall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            // revert if result = 0
            if iszero(result) {
                let size := returndatasize()
                returndatacopy(0, 0, size)
                revert(0, size)
            }
        }
    }

}