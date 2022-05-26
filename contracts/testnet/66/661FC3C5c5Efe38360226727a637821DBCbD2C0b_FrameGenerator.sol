// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@thirdweb-dev/contracts/ThirdwebContract.sol';

import '../../interfaces/IFrameSVGs.sol';
import '../../interfaces/IFrameGenerator.sol';

/// @dev Generate Frame SVG and properties
contract FrameGenerator is ThirdwebContract, IFrameGenerator {
	using Strings for uint16;

	IFrameSVGs immutable frameSVGs1;
	IFrameSVGs immutable frameSVGs2;

	constructor(FrameSVGs memory svgs) {
		frameSVGs1 = svgs.frameSVGs1;
		frameSVGs2 = svgs.frameSVGs2;
	}

	function generateFrame(uint16 frame)
		external
		view
		override
		returns (IFrameSVGs.FrameData memory)
	{
		if (frame <= 3) {
			return callFrameSVGs(frameSVGs1, frame);
		}

		if (frame <= 5) {
			return callFrameSVGs(frameSVGs2, frame);
		}

		revert('invalid frame selection');
	}

	function callFrameSVGs(IFrameSVGs target, uint16 frame)
		internal
		view
		returns (IFrameSVGs.FrameData memory)
	{
		bytes memory functionSelector = abi.encodePacked('frame_', uint16(frame).toString(), '()');

		bool success;
		bytes memory result;
		(success, result) = address(target).staticcall(
			abi.encodeWithSelector(bytes4(keccak256(functionSelector)))
		);

		return abi.decode(result, (IFrameSVGs.FrameData));
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./feature/Ownable.sol";
import "./interfaces/IContractDeployer.sol";

contract ThirdwebContract is Ownable {
    uint256 private hasSetOwner;

    /// @dev Initializes the owner of the contract.
    function tw_initializeOwner(address deployer) external {
        require(hasSetOwner == 0, "Owner already initialized");
        hasSetOwner = 1;
        owner = deployer;
    }

    /// @dev Returns whether owner can be set
    function _canSetOwner() internal virtual override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Enable access to the original contract deployer in the constructor. If this function is called outside of a constructor, it will return address(0) instead.
    function _contractDeployer() internal view returns (address) {
        if (address(this).code.length == 0) {
            try IContractDeployer(msg.sender).getContractDeployer(address(this)) returns (address deployer) {
                return deployer;
            } catch {
                return address(0);
            }
        }
        return address(0);
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameSVGs {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
    struct FrameSVGs {
        IFrameSVGs frameSVGs1;
        IFrameSVGs frameSVGs2;
    }

    /// @param Frame uint representing Frame selection
    /// @return FrameData containing svg snippet and Frame title and Frame type
    function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public override owner;

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) public override {
        require(_canSetOwner(), "Not authorized");

        address _prevOwner = owner;
        owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractDeployer {
    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a contract is deployed.
    event ContractDeployed(address indexed deployer, address indexed publisher, address deployedContract);

    /**
     *  @notice Deploys an instance of a published contract directly.
     *
     *  @param publisher        The address of the publisher.
     *  @param contractBytecode The bytecode of the contract to deploy.
     *  @param constructorArgs  The encoded constructor args to deploy the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstance(
        address publisher,
        bytes memory contractBytecode,
        bytes memory constructorArgs,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    /**
     *  @notice Deploys a clone pointing to an implementation of a published contract.
     *
     *  @param publisher        The address of the publisher.
     *  @param implementation   The contract implementation for the clone to point to.
     *  @param initializeData   The encoded function call to initialize the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI and for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstanceProxy(
        address publisher,
        address implementation,
        bytes memory initializeData,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    function getContractDeployer(address _contract) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);
}