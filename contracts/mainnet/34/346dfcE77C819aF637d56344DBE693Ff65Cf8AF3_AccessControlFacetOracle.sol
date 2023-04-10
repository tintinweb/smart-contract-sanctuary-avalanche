// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAccessControlOracle } from "../interfaces/IAccessControlOracle.sol";

import { LibOracleStructStorage } from "../libraries/LibOracleStructStorage.sol";
import { LibAccessControlStorageOracle } from "../libraries/LibAccessControlStorageOracle.sol";

// Since we are using DiamondPattern, one can no longer directly inherit contracts from Openzeppelin.
// This happens since DiamondPattern implies a different storage structure, but OpenZeppelin handles memory internally.
// Following contract is inspired from OpenZeppelin's Ownable2Step.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol

/**
 * @title  Oracle Diamond Access Control Implementation
 * @dev    Inspired by OpenZeppelin's AccessControl Roles implementation, but adapted to Diamond Pattern storage
 * @dev    Also implements activation/deactivations of functionalities by owners
 */
contract AccessControlFacetOracle is IAccessControlOracle {
	/**
	 * @dev  Prevents initializating more than once
	 */
	modifier notInitialized() {
		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();

		require(!s._initialized, LibOracleStructStorage.LIB_ORACLE_STORAGE_ALREADY_INITIALIZED);
		s._initialized = true;
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(
			msg.sender == LibAccessControlStorageOracle.getStorage()._owner,
			LibOracleStructStorage.SHOULD_BE_OWNER
		);
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the proposed new owner
	 */
	modifier onlyProposedNewOwner() {
		require(
			msg.sender == LibAccessControlStorageOracle.getStorage()._proposedNewOwner,
			LibOracleStructStorage.SHOULD_BE_PROPOSED_NEW_OWNER
		);
		_;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev    Similar to OpenZeppelin's Transparent Proxy initialize function
	 * @dev    Intended to be called after deployment, on the Diamond, to alter Diamond's storage
	 * @dev    Currently called from off-chain, after all contracts' creation, through a script
	 * @dev    Addresses should be unique, no address can have multiple roles or responsabilities
	 */
	function initAccessControlFacet(address owner, address cerchiaDRT) external notInitialized {
		require(owner != cerchiaDRT, LibOracleStructStorage.OWNER_CAN_NOT_BE_CERCHIA_DRT);

		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();
		s._owner = owner;
		s._cerchiaDRTAddress = cerchiaDRT;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev  Owner can propose a new owner.
	 * @param newOwner this address becomes new owner after accepting the ownership transfer
	 */
	function requestOwnershipTransfer(address newOwner) external onlyOwner {
		LibAccessControlStorageOracle.getStorage()._proposedNewOwner = newOwner;

		emit RequestOwnershipTransfer(msg.sender, newOwner);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev  The proposed new owner accepts the ownership transfer,
	 *          thus becoming the owner and setting proposed new owner to address(0)
	 */
	function confirmOwnershipTransfer() external onlyProposedNewOwner {
		delete LibAccessControlStorageOracle.getStorage()._proposedNewOwner;

		_transferOwnership(msg.sender);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev   The owner can cancel the proposed ownership transfer, setting proposed new owner to address(0)
	 */
	function cancelOwnershipTransfer() external onlyOwner {
		address proposedNewOwner = LibAccessControlStorageOracle.getStorage()._proposedNewOwner;
		delete LibAccessControlStorageOracle.getStorage()._proposedNewOwner;

		emit CancelOwnershipTransfer(msg.sender, proposedNewOwner);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The owner of the Oracle Diamond
	 */
	function getOwner() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._owner;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The proposed new owner of the Oracle Diamond
	 */
	function getProposedNewOwner() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._proposedNewOwner;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The address of the CerchiaDRT Diamond
	 */
	function getCerchiaDRTAddress() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._cerchiaDRTAddress;
	}

	/**
	 * @dev Helper function to transfer ownership
	 */
	function _transferOwnership(address newOwner) internal {
		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();

		address oldOwner = s._owner;
		s._owner = newOwner;
		emit OwnershipTransfered(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title  Oracle Diamond Access Control Interface
 * @notice Used to control what functions an address can call
 */
interface IAccessControlOracle {
	/**
	 * @notice Emitted when ownership was transfered to someone else
	 */
	event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);

	/**
	 * @notice Emitted when a new owner was proposed
	 */
	event RequestOwnershipTransfer(address indexed owner, address indexed proposedNewOwner);

	/**
	 * @notice Emitted when a new owner proposal was canceled
	 */
	event CancelOwnershipTransfer(address indexed owner, address indexed canceledProposedNewOwner);

	/**
	 * @param  owner  Address to be the owner of the Oracle Diamond
	 * @param  cerchiaDRT  Address of the CerchiaDRT Diamond
	 */
	function initAccessControlFacet(address owner, address cerchiaDRT) external;

	/**
	 * @notice  For owner, to propose a new owner
	 */
	function requestOwnershipTransfer(address newOwner) external;

	/**
	 * @notice  For proposed new owner, to accept ownership
	 */
	function confirmOwnershipTransfer() external;

	/**
	 * @notice  For owner, to cancel the new owner proposal
	 */
	function cancelOwnershipTransfer() external;

	/**
	 * @notice Returns address of owner
	 */
	function getOwner() external view returns (address);

	/**
	 * @notice Returns address of proposed new owner
	 */
	function getProposedNewOwner() external view returns (address);

	/**
	 * @notice Returns address of CerchiaDRT
	 */
	function getCerchiaDRTAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Diamond Storage for Oracle Diamond's access control functions
 */
library LibAccessControlStorageOracle {
	bytes32 public constant ACCESS_CONTROL_STORAGE_SLOT_ORACLE = keccak256("ACCESS.CONTROL.STORAGE.ORACLE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct AccessControlStorageOracle {
		// Owner of Oracle Diamond, address allowed to call OwnerSetLevel
		address _owner;
		// Proposed new owner of Oracle Diamond, for Ownable2Step flow
		address _proposedNewOwner;
		// Address of CerchiaDRT Diamond, used to enforce Oracle flow only being initiated by CerchiaDRT
		address _cerchiaDRTAddress;
		// True if AccessControlStorageOracle was initialized
		bool _initialized;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory, holding our AccessControlStorageOracle struct
	 */
	function getStorage() internal pure returns (AccessControlStorageOracle storage s) {
		bytes32 position = ACCESS_CONTROL_STORAGE_SLOT_ORACLE;
		assembly {
			s.slot := position
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Wrapper library storing constants and structs of Oracle Diamond
 */
library LibOracleStructStorage {
	// Error codes with descriptive names
	string public constant SHOULD_BE_OWNER = "16";
	string public constant LIB_ORACLE_STORAGE_ALREADY_INITIALIZED = "501";
	string public constant INVALID_REQUEST_ID = "502";
	string public constant LEVEL_DATA_IS_NOT_VALID = "503";
	string public constant ORACLE_IS_NOT_WORKING = "504";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "505";
	string public constant ORACLE_CALLER_CAN_ONLY_BE_CERCHIA_DRT = "506";
	string public constant SHOULD_BE_PROPOSED_NEW_OWNER = "507";
	string public constant OWNER_CAN_NOT_BE_CERCHIA_DRT = "508";

	// Value representing invalid index level from off-chain API
	int128 public constant INVALID_LEVEL_VALUE = type(int128).min;
}