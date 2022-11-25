// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMultichainDeployer {
    function deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes calldata bytecode_
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {
    Create2Deployer
} from "oz-custom/contracts/internal/DeterministicDeployer.sol";

import "./interfaces/IMultichainDeployer.sol";

contract MultichainDeployer is Create2Deployer, IMultichainDeployer {
    /// @dev value is equal to keccak256("MultichainDeployer_v1")
    bytes32 public constant VERSION =
        0x9eea8cb98c11fea36be219299200e6b67153ef85e64f26fbca079445a66e02d2;

    function deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes calldata bytecode_
    ) external payable {
        _deploy(amount_, salt_, bytecode_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz/utils/Create2.sol";

import "../libraries/Create3.sol";

abstract contract DeterministicDeployer {
    event Deployed(
        address indexed instance,
        bytes32 indexed salt,
        bytes32 indexed bytecodeHash,
        string factory
    );

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal virtual;
}

abstract contract Create2Deployer is DeterministicDeployer {
    function instanceOf(bytes32 salt_, bytes32 bytecodeHash_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = Create2.computeAddress(salt_, bytecodeHash_);
        isDeployed = instance.code.length != 0;
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal override {
        address instance = Create2.deploy(amount_, salt_, bytecode_);

        emit Deployed(
            instance,
            salt_,
            instance.codehash,
            type(Create2Deployer).name
        );
    }
}

abstract contract Create3Deployer is DeterministicDeployer {
    function instanceOf(bytes32 salt_)
        external
        view
        returns (address instance, bool isDeployed)
    {
        instance = Create3.getDeployed(salt_);
        isDeployed = instance.code.length != 0;
    }

    function _deploy(
        uint256 amount_,
        bytes32 salt_,
        bytes memory bytecode_
    ) internal override {
        address instance = Create3.deploy(salt_, bytecode_, amount_);

        emit Deployed(
            instance,
            salt_,
            instance.codehash,
            type(Create3Deployer).name
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Bytes32Address} from "./Bytes32Address.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library Create3 {
    using Bytes32Address for bytes32;

    error Create3__DeploymentFailed();

    error Create3__InitializationFailed();

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    uint256 internal constant PROXY_BYTECODE =
        0x67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3;

    /// @dev value is equal to keccak256(PROXY_BYTECODE)
    bytes32 internal constant PROXY_BYTECODE_HASH =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        assembly {
            // Store the `PROXY_BYTECODE` into scratch space.
            mstore(0x00, PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `Create3__DeploymentFailed()`.
                mstore(0x00, 0xf40611d7)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x00, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            mstore8(0x0a, 0xd6)
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore8(0x0b, 0x94)
            // Nonce of the proxy contract (1).
            mstore8(0x20, 0x01)
            // Shift left and back to clear the upper 96 bits.
            deployed := shr(96, shl(96, keccak256(0x0a, 0x17)))

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `Create3__InitializationFailed()`.
                mstore(0x00, 0x4a663aaa)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `Create3__InitializationFailed()`.
                mstore(0x00, 0x4a663aaa)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function getDeployed(bytes32 salt)
        internal
        view
        returns (address deployed)
    {
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x00, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            mstore8(0x0a, 0xd6)
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore8(0x0b, 0x94)
            // Nonce of the proxy contract (1).
            mstore8(0x20, 0x01)
            // Shift left and back to clear the upper 96 bits.
            deployed := shr(96, shl(96, keccak256(0x0a, 0x17)))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.17;

error Create2__DeploymentFailed();
error Create2__ZeroLengthByteCode();
error Create2__InsufficientBalance();

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        if (address(this).balance < amount)
            revert Create2__InsufficientBalance();
        if (bytecode.length == 0) revert Create2__ZeroLengthByteCode();
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) revert Create2__DeploymentFailed();
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash)
        internal
        view
        returns (address)
    {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        assembly {
            addr := _data
        }
    }
}