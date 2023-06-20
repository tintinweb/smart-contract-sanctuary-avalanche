// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Diamond Storage for Oracle Diamond's functions, except access control
 */
library LibCerchiaOracleStorage {
	bytes32 public constant CERCHIA_ORACLE_STORAGE_SLOT = keccak256("CERCHIA.ORACLE.STORAGE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct CerchiaOracleStorage {
		// Mapping from requestId, to who initiated it. It should always be CerchiaDRT Diamond
		mapping(uint256 => address) requests;
		// Counter for the next requestId to assign to an incoming request
		uint256 requestId;
		// True if Oracle is working
		bool _isWorking;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory
	 */
	function getStorage() external pure returns (CerchiaOracleStorage storage s) {
		bytes32 position = CERCHIA_ORACLE_STORAGE_SLOT;
		assembly {
			s.slot := position
		}
	}
}