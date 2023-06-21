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