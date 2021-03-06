// SPDX-License-Identifier: MIT
/// @author modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts)

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@thirdweb-dev/contracts/ThirdwebContract.sol';

import '../../interfaces/IFieldSVGs.sol';
import '../../interfaces/IFieldGenerator.sol';

/// @dev Generate Field SVG and properties
contract FieldGenerator is ThirdwebContract, IFieldGenerator {
	using Strings for uint16;

	mapping(uint24 => Color) public _colors;

	IFieldSVGs immutable fieldSVGs1;
	IFieldSVGs immutable fieldSVGs2;
	IFieldSVGs immutable fieldSVGs3;
	IFieldSVGs immutable fieldSVGs4;
	IFieldSVGs immutable fieldSVGs5;
	IFieldSVGs immutable fieldSVGs6;
	IFieldSVGs immutable fieldSVGs7;
	IFieldSVGs immutable fieldSVGs8;
	IFieldSVGs immutable fieldSVGs9;
	IFieldSVGs immutable fieldSVGs10;
	IFieldSVGs immutable fieldSVGs11;
	IFieldSVGs immutable fieldSVGs12;
	IFieldSVGs immutable fieldSVGs13;
	IFieldSVGs immutable fieldSVGs14;
	IFieldSVGs immutable fieldSVGs15;
	IFieldSVGs immutable fieldSVGs16;
	IFieldSVGs immutable fieldSVGs17;
	IFieldSVGs immutable fieldSVGs18;
	IFieldSVGs immutable fieldSVGs19;
	IFieldSVGs immutable fieldSVGs20;
	IFieldSVGs immutable fieldSVGs21;
	IFieldSVGs immutable fieldSVGs22;
	IFieldSVGs immutable fieldSVGs23;
	IFieldSVGs immutable fieldSVGs24;

	constructor(
		uint24[] memory __colors,
		string[] memory titles,
		FieldSVGs memory svgs
	) {
		require(__colors.length == titles.length, 'invalid array lengths');
		for (uint256 i = 0; i < __colors.length; i++) {
			require(__colors[i] != 0, 'FieldGenerator: colors cannot be 0');
			_colors[__colors[i]] = Color({title: titles[i], exists: true});
			emit ColorAdded(__colors[i], titles[i]);
		}

		fieldSVGs1 = svgs.fieldSVGs1;
		fieldSVGs2 = svgs.fieldSVGs2;
		fieldSVGs3 = svgs.fieldSVGs3;
		fieldSVGs4 = svgs.fieldSVGs4;
		fieldSVGs5 = svgs.fieldSVGs5;
		fieldSVGs6 = svgs.fieldSVGs6;
		fieldSVGs7 = svgs.fieldSVGs7;
		fieldSVGs8 = svgs.fieldSVGs8;
		fieldSVGs9 = svgs.fieldSVGs9;
		fieldSVGs10 = svgs.fieldSVGs10;
		fieldSVGs11 = svgs.fieldSVGs11;
		fieldSVGs12 = svgs.fieldSVGs12;
		fieldSVGs13 = svgs.fieldSVGs13;
		fieldSVGs14 = svgs.fieldSVGs14;
		fieldSVGs15 = svgs.fieldSVGs15;
		fieldSVGs16 = svgs.fieldSVGs16;
		fieldSVGs17 = svgs.fieldSVGs17;
		fieldSVGs18 = svgs.fieldSVGs18;
		fieldSVGs19 = svgs.fieldSVGs19;
		fieldSVGs20 = svgs.fieldSVGs20;
		fieldSVGs21 = svgs.fieldSVGs21;
		fieldSVGs22 = svgs.fieldSVGs22;
		fieldSVGs23 = svgs.fieldSVGs23;
		fieldSVGs24 = svgs.fieldSVGs24;
	}

	// Extended color list causes error deploying due to gas limit. Here we can add further colors
	function addColors(uint24[] memory __colors, string[] memory titles) external {
		require(__colors.length == titles.length, 'invalid array lengths');
		for (uint256 i = 0; i < __colors.length; i++) {
			require(__colors[i] != 0, 'FieldGenerator: colors cannot be 0');
			_colors[__colors[i]] = Color({title: titles[i], exists: true});
			emit ColorAdded(__colors[i], titles[i]);
		}
	}

	function colorExists(uint24 color) public view override returns (bool) {
		return _colors[color].exists;
	}

	function colorTitle(uint24 color) public view override returns (string memory) {
		return _colors[color].title;
	}

	function callFieldSVGs(
		IFieldSVGs target,
		uint16 field,
		uint24[4] memory colors
	) internal view returns (IFieldSVGs.FieldData memory) {
		bytes memory functionSelector = abi.encodePacked(
			'field_',
			uint16(field).toString(),
			'(uint24[4])'
		);

		bool success;
		bytes memory result;
		(success, result) = address(target).staticcall(
			abi.encodeWithSelector(bytes4(keccak256(functionSelector)), colors)
		);

		return abi.decode(result, (IFieldSVGs.FieldData));
	}

	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		override
		returns (IFieldSVGs.FieldData memory)
	{
		if (field <= 27) {
			return callFieldSVGs(fieldSVGs1, field, colors);
		}

		if (field <= 50) {
			return callFieldSVGs(fieldSVGs2, field, colors);
		}

		if (field <= 66) {
			return callFieldSVGs(fieldSVGs3, field, colors);
		}

		if (field <= 89) {
			return callFieldSVGs(fieldSVGs4, field, colors);
		}

		if (field <= 110) {
			return callFieldSVGs(fieldSVGs5, field, colors);
		}

		if (field <= 132) {
			return callFieldSVGs(fieldSVGs6, field, colors);
		}

		if (field <= 150) {
			return callFieldSVGs(fieldSVGs7, field, colors);
		}

		if (field <= 170) {
			return callFieldSVGs(fieldSVGs8, field, colors);
		}

		if (field <= 177) {
			return callFieldSVGs(fieldSVGs9, field, colors);
		}

		if (field <= 193) {
			return callFieldSVGs(fieldSVGs10, field, colors);
		}

		if (field <= 198) {
			return callFieldSVGs(fieldSVGs11, field, colors);
		}

		if (field <= 205) {
			return callFieldSVGs(fieldSVGs12, field, colors);
		}

		if (field <= 211) {
			return callFieldSVGs(fieldSVGs13, field, colors);
		}

		if (field <= 217) {
			return callFieldSVGs(fieldSVGs14, field, colors);
		}

		if (field <= 223) {
			return callFieldSVGs(fieldSVGs15, field, colors);
		}

		if (field <= 227) {
			return callFieldSVGs(fieldSVGs16, field, colors);
		}

		if (field <= 233) {
			return callFieldSVGs(fieldSVGs17, field, colors);
		}

		if (field <= 243) {
			return callFieldSVGs(fieldSVGs18, field, colors);
		}

		if (field <= 262) {
			return callFieldSVGs(fieldSVGs19, field, colors);
		}

		if (field <= 275) {
			return callFieldSVGs(fieldSVGs20, field, colors);
		}

		if (field <= 284) {
			return callFieldSVGs(fieldSVGs21, field, colors);
		}

		if (field <= 289) {
			return callFieldSVGs(fieldSVGs22, field, colors);
		}

		if (field <= 298) {
			return callFieldSVGs(fieldSVGs23, field, colors);
		}

		if (field == 299) {
			return callFieldSVGs(fieldSVGs24, field, colors);
		}

		revert('invalid field selection');
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './IFieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
	/// @param field uint representing field selection
	/// @param colors to be rendered in the field svg
	/// @return FieldData containing svg snippet and field title
	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		returns (IFieldSVGs.FieldData memory);

	event ColorAdded(uint24 color, string title);

	struct Color {
		string title;
		bool exists;
	}

	function addColors(uint24[] calldata colors, string[] calldata titles) external;

	/// @notice Returns true if color exists in contract, else false.
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorExists(uint24 color) external view returns (bool);

	/// @notice Returns the title string corresponding to the 3-byte color
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorTitle(uint24 color) external view returns (string memory);

	struct FieldSVGs {
		IFieldSVGs fieldSVGs1;
		IFieldSVGs fieldSVGs2;
		IFieldSVGs fieldSVGs3;
		IFieldSVGs fieldSVGs4;
		IFieldSVGs fieldSVGs5;
		IFieldSVGs fieldSVGs6;
		IFieldSVGs fieldSVGs7;
		IFieldSVGs fieldSVGs8;
		IFieldSVGs fieldSVGs9;
		IFieldSVGs fieldSVGs10;
		IFieldSVGs fieldSVGs11;
		IFieldSVGs fieldSVGs12;
		IFieldSVGs fieldSVGs13;
		IFieldSVGs fieldSVGs14;
		IFieldSVGs fieldSVGs15;
		IFieldSVGs fieldSVGs16;
		IFieldSVGs fieldSVGs17;
		IFieldSVGs fieldSVGs18;
		IFieldSVGs fieldSVGs19;
		IFieldSVGs fieldSVGs20;
		IFieldSVGs fieldSVGs21;
		IFieldSVGs fieldSVGs22;
		IFieldSVGs fieldSVGs23;
		IFieldSVGs fieldSVGs24;
	}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICategories {
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}

	enum FrameCategories {
		NONE,
		ADORNED,
		MENACING,
		SECURED,
		FLORIATED,
		EVERLASTING
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IColors {
	event ColorAdded(uint24 color, string title);

	struct Color {
		string title;
		bool exists;
	}

	/// @notice Returns true if color exists in contract, else false.
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorExists(uint24 color) external view returns (bool);

	/// @notice Returns the title string corresponding to the 3-byte color
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorTitle(uint24 color) external view returns (string memory);
}