/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/SharedStructs.sol


pragma solidity >=0.7.0 <0.9.0;


library SharedStructs {
    // Holds data for players
    struct Player {
        // ----------------- Troops
        // [0] cyborgs [1] mechas [2] beasts [3] demigods || Placeholders for more
        uint256[10] warriorsByTier;
        // [0] fences [1] militians [2] protectors [3] zeus lightnings || Placeholders for more
        uint256[10] defensesByTier;
        // [0] hydras [1] Blood of Ares  || Placeholders for more
        uint256[10] upgradesByTier;
        // represents the attack power given by warriors
        uint256 attackPower;
        // represents the defense power given by defenses
        uint256 defensePower;
        // Current shares (attackPower + defensePower). Shares go back to 0 once ROI is reached
        uint256 shares;
        // current tier based on the shares, on ranks[]
        uint256 tier;
        // ----------------- Buildings
        // [0] excavator [1] garage [2] radar [3] robbery school || placeholders for more
        uint256[10] buildings;
        // ----------------- Statistics
        // [0] count of defenses [1] won defenses [2] lost defenses [3] total avax lose || placeholders for more
        uint256[10] defensesStats;
        // [0] count of attacks [1] won attacks [2] lost attacks [3] total avax won || placeholders for more
        uint256[10] attacksStats;
        // ----------------- Shares & Rewards
        // amount of avax lost to fights since last claim
        uint256 totalLostSinceLastClaim;
        // amount of avax won from fights since last claim
        uint256 totalWonSinceLastClaim;
        // total avax claimed ever
        uint256 totalClaimed;
        // Time of last claim
        uint256 lastClaimTime;
        // epoch when last claim
        uint256 lastClaimEpoch;
        // Time when claim unlocks
        uint256 nextClaimTime;
        // Time for your next attack
        uint256 attackUnlocksTime;
        // Indicates if player has ROId
        bool isROI;
    }

    // Holds data for snapshots
    struct EpochSnapshot {
        // timestamp of the snapshot
        uint256 timestamp;
        // total shares at snapshot
        uint256 totalShares;
        // rewards to distribute this epoch
        uint256 totalRewards;
    }
}

// File: hardhat/console.sol


pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/CyberGods_Game.sol


pragma solidity ^0.8.4;




contract CyberGods_Data is Ownable {
    // This contract holds all the data for the CyberGods Game
    // Logic implemented in another Contract

    // Map address to Player
    mapping(address => SharedStructs.Player) private players;
    // Map Snapshot index to Snapshot
    mapping(uint256 => SharedStructs.EpochSnapshot) public epochSnapshots;
    // Map tier to count of players
    mapping(uint256 => uint256) public playersInTiers;
    // Map address to player username
    mapping(address => string) public playersToUsername;

    // Array of address, used for quickly looping over accounts when retrieving players in a tier
    address[] private playersAddress;
    // Game Contract address
    address gameContract;
    // Fees Manager Contract Address
    address public feesManagerAddress;

    // Total Unclaimed rewards
    uint256 public totalRewardsPending = 0;
    // Total Claimed rewards
    uint256 public totalRewardsClaimed = 0;
    // Total rewards distributed since Epoch 1
    uint256 public totalRewards = 0;
    // Total cumulative amount of Avax ever that was in the pool
    uint256 public totalCumulativeAvax = 0;

    // Total Players in Game
    uint256 public totalPlayers = 0;
    // Total Shares of all Players
    uint256 public totalShares = 0;
    // Current Epoch
    uint256 public currentEpoch = 0;
    // Next Epoch Time
    uint256 public nextEpochTime = 0;

    // Verifies if the sender is the Game contract
    modifier onlyAuthorized() {
        require(
            msg.sender == gameContract || msg.sender == owner(),
            "Caller is not authorized"
        );
        _;
    }

    constructor(address _feesManagerAddress) {
        feesManagerAddress = _feesManagerAddress;
    }

    // Allows Fee Manager to send funds
    receive() external payable {
        totalCumulativeAvax += msg.value;
    }

    // Emergency withdraw
    function adminEmergencyWithdraw() external onlyOwner {
        totalRewardsPending = 0;
        payable(owner()).transfer(getTotalPoolBalance());
    }

    function adminRemovePlayer(address _player) external onlyOwner {
        delete players[_player];
    }

    // Player functions -----
    // ----------------------
    // ----------------------

    // Get a player's information - admin only
    // _player: the player address
    // returns a Player
    function adminGetPlayerInformation(address _player)
        external
        view
        onlyOwner
        returns (SharedStructs.Player memory)
    {
        return players[_player];
    }

    // Called from Game Contract
    function setBuildings(
        address _player,
        uint256 _buildingId,
        uint256 _toLevel
    ) public onlyAuthorized {
        players[_player].buildings[_buildingId] = _toLevel;
    }

    // Get a player
    // _player: the player's address
    // returns a Player
    function getPlayer(address _player)
        public
        view
        onlyAuthorized
        returns (SharedStructs.Player memory)
    {
        return players[_player];
    }

    // Updates a player's attacks stats
    // _player: the players address
    // _stats: the stats array to set
    function setAttacksStats(address _player, uint256[10] memory _stats)
        public
        onlyAuthorized
    {
        players[_player].attacksStats = _stats;
    }

    // Updates a player's defenses stats
    // _player: the players address
    // _stats: the stats array to set
    function setDefensesStats(address _player, uint256[10] memory _stats)
        public
        onlyAuthorized
    {
        players[_player].defensesStats = _stats;
    }

    // set the total avax won since last claim
    // _player: the player's address
    // _value: the value to set
    function setTotalWonSinceLastClaim(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalWonSinceLastClaim = _value;
    }

    // set the total avax lost since last claim
    // _player: the player's address
    // _value: the value to set
    function setTotalLostSinceLastClaim(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalLostSinceLastClaim = _value;
    }

    function claimForPlayer(
        address _player,
        uint256 rewards,
        uint256 _nextClaimTime
    ) public onlyAuthorized {
        totalRewardsPending -= rewards;
        totalRewardsClaimed += rewards;

        players[_player].totalClaimed += rewards;
        players[_player].totalWonSinceLastClaim = 0;
        players[_player].totalLostSinceLastClaim = 0;
        players[_player].lastClaimTime = block.timestamp;
        players[_player].nextClaimTime = _nextClaimTime;
        players[_player].lastClaimEpoch = currentEpoch;
        payable(_player).transfer(rewards);
    }

    function setTotalClaimed(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalClaimed = _value;
    }

    function setLastClaimTime(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].lastClaimTime = _value;
    }

    function setLastClaimEpoch(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].lastClaimEpoch = _value;
    }

    function setTier(
        address _toPlayer,
        bool _isNewPlayer,
        uint256 _tier
    ) public onlyAuthorized {
        if (!_isNewPlayer) {
            playersInTiers[players[_toPlayer].tier]--;
        }

        players[_toPlayer].tier = _tier;
        playersInTiers[_tier]++;
    }

    function setWarriorsByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].warriorsByTier[_tier] = _qty;
    }

    function setAttackPower(address _player, uint256 _attackPower)
        public
        onlyAuthorized
    {
        players[_player].attackPower = _attackPower;
    }

    function setDefensesByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].defensesByTier[_tier] = _qty;
    }

    function setDefensePower(address _player, uint256 _defensePower)
        public
        onlyAuthorized
    {
        players[_player].defensePower = _defensePower;
    }

    function setUpgradesByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].upgradesByTier[_tier] = _qty;
    }

    function setShares(address _player, uint256 _shares) public onlyAuthorized {
        players[_player].shares = _shares;
    }

    function setNextClaimTime(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].nextClaimTime = _value;
    }

    function setIsROI(address _player, bool _isROI) public onlyAuthorized {
        players[_player].isROI = _isROI;
    }

    function updatePlayerLastClaimEpoch(address _player) public onlyAuthorized {
        players[_player].lastClaimEpoch = currentEpoch;
    }

    function setAttackUnlocksTime(address _player, uint256 _unlockTime)
        public
        onlyAuthorized
    {
        players[_player].attackUnlocksTime = _unlockTime;
    }

    // End Player functions -
    // ----------------------
    // ----------------------

    // Epochs functions -----
    // ----------------------
    // ----------------------
    function setNextEpochTime(uint256 _value) public onlyAuthorized {
        nextEpochTime = _value;
    }

    function createEpochSnapshot(
        uint256 _timestamp,
        uint256 _totalShares,
        uint256 _totalRewardsThisEpoch
    ) public onlyAuthorized {
        SharedStructs.EpochSnapshot memory snapshot = SharedStructs
            .EpochSnapshot(_timestamp, _totalShares, _totalRewardsThisEpoch);
        epochSnapshots[currentEpoch] = snapshot;
        currentEpoch++;
    }

    function getEpochSnapshot(uint256 _epochIndex)
        public
        view
        returns (SharedStructs.EpochSnapshot memory)
    {
        return epochSnapshots[_epochIndex];
    }

    // End Epochs functions -
    // ----------------------
    // ----------------------

    // Username functions -----
    // ----------------------
    // ----------------------

    // set a player's username
    // _player: the player's address
    // _username: the username
    function setUsernameForPlayer(address _player, string memory _username)
        public
        onlyAuthorized
    {
        playersToUsername[_player] = _username;
    }

    // remove a player's username
    // _player: the player's address
    function deleteUsernameForPlayer(address _player) public onlyAuthorized {
        delete playersToUsername[_player];
    }

    // Force changes username of a player
    // _address: the player's address
    // _username: the username
    function adminSetUsername(address _address, string memory _username)
        external
        onlyOwner
    {
        playersToUsername[_address] = _username;
    }

    // End Username functions -
    // ----------------------
    // ----------------------

    // Get the list of addresses playing the game
    function getPlayersAddresses() external view returns (address[] memory) {
        return playersAddress;
    }

    // Get player count in tier
    function getPlayerAddress(uint256 _index)
        external
        view
        onlyAuthorized
        returns (address)
    {
        return playersAddress[_index];
    }

    function addNewAddress(address _newPlayer) public onlyAuthorized {
        playersAddress.push(_newPlayer);
        totalPlayers++;
    }

    // ADMIN FUNCTIONS ---------------------

    // Set the Game Contract address
    // _gameContract: the contract address
    function adminSetGameContract(address _gameContract) external onlyOwner {
        gameContract = _gameContract;
    }

    // Set the Fees Manager Contract address
    // _feesManagerAddress: the contract address
    function adminSetFeesManagerAddress(address _feesManagerAddress)
        external
        onlyOwner
    {
        feesManagerAddress = _feesManagerAddress;
    }

    // onlyAuthorized ------------
    function setTotalRewardsPending(uint256 _value) public onlyAuthorized {
        totalRewardsPending = _value;
    }

    function setTotalRewards(uint256 _value) public onlyAuthorized {
        totalRewards = _value;
    }

    function setTotalRewardsClaimed(uint256 _value) public onlyAuthorized {
        totalRewardsClaimed = _value;
    }

    // Get the game pool's balance, minus the pending rewards
    function getPoolBalanceMinusRewards() public view returns (uint256) {
        return address(this).balance - totalRewardsPending;
    }

    // Get the game pool balance
    function getTotalPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setTotalShares(uint256 _totalShares) public onlyAuthorized {
        totalShares = _totalShares;
    }

    function setTotalPlayers(uint256 _value) public onlyAuthorized {
        totalPlayers = _value;
    }

    function setCurrentEpoch(uint256 _value) public onlyAuthorized {
        currentEpoch = _value;
    }
}


contract CyberGods_Game is Ownable, Pausable {
    CyberGods_Data private dataContract;

    struct PlayerInTier {
        address playerAddress;
        string username;
        uint256 rewards;
        uint256 defensePower;
        uint256 hydras;
    }

    // Emited when a player attacks another one
    event AttackResult(address winner, address loser, address engager);
    /// Emited when a player upgrades a building
    event UpgradeBuilding(address player, uint256 buildingId, uint256 toLevel);

    uint256 private constant MULTIPLIER = 1e18;

    // Fees Manager Contract Address
    address public feesManagerAddress;

    // Cost to change username in game
    uint256 public changeUsernamePrice = 250000000000000000;
    // Fee going to the Game Pool
    uint256 public gamePoolFee = 60;
    // % of deposits of a player to ROI
    uint256 public maxROI = 200;
    // even if pool can sustain a higher APR, limit to this amount of Avax per share per day
    uint256 public maxDailyAvaxPerShare = 7500000000000000;
    // when pool cannot sustain 0.0075 avax per day anymore, the APR is calculated on a 90 days runway
    uint256 public runwayInDays = 90;
    // number of epochs per day
    uint256 public epochsPerDay = 8;
    // The boost provided to each Demi Gods by Ades Blood upgrade
    uint256 public aresBloodBoost = 2;

    // Values for Buildings
    // Values for Troops && Upgrades
    uint256[4] public warriorsSharesTiers = [1, 2, 3, 4];
    uint256[4] public defensesSharesTiers = [1, 2, 3, 4];
    uint256[2] public upgradesSharesTiers = [5, 0];

    uint256[4] public warriorsAvaxPriceTiers = [
        0.5 ether,
        1 ether,
        1.5 ether,
        2 ether
    ];
    uint256[4] public defensesAvaxPriceTiers = [
        0.5 ether,
        1 ether,
        1.5 ether,
        2 ether
    ];
    uint256[2] public upgradesAvaxPriceTiers = [2.5 ether, 2.5 ether];

    // Supply of Troops & Upgrades
    uint256[4] public warriorsMaxSupplyTiers = [1000, 750, 500, 250];
    uint256[4] public defensesMaxSupplyTiers = [1000, 750, 500, 250];
    uint256[2] public upgradesMaxSupplyTiers = [100, 100];

    // Current supply of Troops & Upgrades
    uint256[4] public warriorsInUseByTiers = [0, 0, 0, 0];
    uint256[4] public defensesInUseByTiers = [0, 0, 0, 0];
    uint256[2] public upgradesInUseByTiers = [0, 0];

    // Max upgrades per tier a player can own
    uint256[2] public maxUpgradesPerTier = [3, 1];
    // In hours, how often a player can claim
    uint256[4] private excavatorLevelValues = [
        24 hours,
        20 hours,
        16 hours,
        12 hours
    ];
    // In hours, how long it takes to recharge Warriors for attack
    uint256[6] private garageLevelValues = [
        6 hours,
        5 hours,
        4 hours,
        3 hours,
        2 hours,
        1 hours
    ];
    // Can see or not enemy players'= upgrades
    uint256[2] private radarLevelValues = [0, 1];
    // In %, amount of Avax a player steals when winning an attack
    uint256[7] private robberySchoolLevelValues = [10, 15, 20, 25, 30, 35, 40];

    uint256[3] private excavatorLevelPrices = [0.5 ether, 1 ether, 1.5 ether];
    uint256[5] private garageLevelPrices = [
        0.75 ether,
        1 ether,
        1.25 ether,
        1.5 ether,
        1.75 ether
    ];
    uint256[1] private radarLevelPrices = [2 ether];
    uint256[6] private robberySchoolLevelPrices = [
        0.25 ether,
        0.5 ether,
        0.75 ether,
        1 ether,
        1.25 ether,
        1.5 ether
    ];

    // Ranks ranges
    uint256[] public ranks = [
        0,
        10,
        20,
        30,
        40,
        50,
        75,
        100,
        200,
        400,
        800,
        1500,
        3000,
        5000,
        7500,
        10000,
        15000,
        20000,
        30000
    ];

    constructor(CyberGods_Data _dataContract, address _feesManagerAddress) {
        dataContract = CyberGods_Data(_dataContract);
        feesManagerAddress = _feesManagerAddress;
    }

    // Pause the contract
    function adminPause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function adminUnpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}

    // Emergency withdraw
    function adminEmergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Upgrades a building for the caller
    // _buildingId: the building Id
    // _toLevel: target level
    function upgradeBuilding(uint256 _buildingId, uint256 _toLevel)
        external
        payable
        whenNotPaused
    {
        require(_buildingId >= 0 && _buildingId <= 3, "Invalid Building");

        uint256 currentBuildingLevel = getPlayerBuildings(msg.sender)[
            _buildingId
        ];

        uint256 totalCost = 0;
        // Excavator
        if (_buildingId == 0) {
            require(
                _toLevel <= excavatorLevelPrices.length,
                "Can't upgrade this building to that level"
            );
            for (uint256 i = currentBuildingLevel; i < _toLevel; i++) {
                totalCost += excavatorLevelPrices[i];
            }
            require(msg.value >= totalCost, "Value below price");
        }
        //Garage
        else if (_buildingId == 1) {
            require(
                _toLevel <= garageLevelPrices.length,
                "Can't upgrade this building to that level"
            );
            for (uint256 i = currentBuildingLevel; i < _toLevel; i++) {
                totalCost += garageLevelPrices[i];
            }
            require(msg.value >= totalCost, "Value below price");
        }
        // Radar
        else if (_buildingId == 2) {
            require(
                _toLevel <= radarLevelPrices.length,
                "Can't upgrade this building to that level"
            );
            for (uint256 i = currentBuildingLevel; i < _toLevel; i++) {
                totalCost += radarLevelPrices[i];
            }
            require(msg.value >= totalCost, "Value below price");
        }
        // Robbery School
        else if (_buildingId == 3) {
            require(
                _toLevel <= robberySchoolLevelPrices.length,
                "Can't upgrade this building to that level"
            );
            for (uint256 i = currentBuildingLevel; i < _toLevel; i++) {
                totalCost += robberySchoolLevelPrices[i];
            }
            require(msg.value >= totalCost, "Value below price");
        }

        dataContract.setBuildings(msg.sender, _buildingId, _toLevel);
        emit UpgradeBuilding(msg.sender, _buildingId, _toLevel);

        _sendFunds(msg.value);
    }

    function _sendFunds(uint256 _value) private {
        uint256 gameFeeAmount = ((_value * gamePoolFee) / 100);
        (bool sentToGame, ) = payable(dataContract).call{value: gameFeeAmount}(
            ""
        );
        (bool sentToFeesManager, ) = payable(feesManagerAddress).call{
            value: _value - gameFeeAmount
        }("");
        if (!sentToGame) revert FailedToSendEther();
        if (!sentToFeesManager) revert FailedToSendEther();
    }

    // Attack a player
    // _playerAddress: the target address
    function attackPlayer(address _targetAddress) external whenNotPaused {
        SharedStructs.Player memory attacker = dataContract.getPlayer(
            msg.sender
        );

        require(
            attacker.attackUnlocksTime < block.timestamp,
            "Cannot attack yet"
        );
        require(msg.sender != _targetAddress, "Cannot attack yourself");

        SharedStructs.Player memory defenser = dataContract.getPlayer(
            _targetAddress
        );

        uint256 attackPower = attacker.attackPower;
        uint256 defensePower = defenser.defensePower;

        // Verify if the defender has Hydras
        if (defenser.upgradesByTier[0] > 0) {
            defensePower += defenser.upgradesByTier[0] * upgradesSharesTiers[0];
        }

        // Verify if the attacker has a blood of ares && Demi Gods to give extra attack power to demi gods
        if (attacker.upgradesByTier[1] > 0 && attacker.warriorsByTier[3] > 0) {
            attackPower += (attacker.warriorsByTier[3] * aresBloodBoost);
        }

        uint256[10] memory attackerStats = attacker.attacksStats;
        uint256[10] memory defenserStats = defenser.defensesStats;

        attackerStats[0]++;
        defenserStats[0]++;

        // Set next attack timer based on caller's Garage level
        dataContract.setAttackUnlocksTime(
            msg.sender,
            block.timestamp + garageLevelValues[attacker.buildings[1]]
        );

        if (attackPower > defensePower) {
            // Calculate how much rewards the attacker gets based on its Robbery School level
            uint256 defenserRewards = (getPlayerRewards(_targetAddress) *
                robberySchoolLevelValues[attacker.buildings[3]]) / 100;

            dataContract.setTotalWonSinceLastClaim(
                msg.sender,
                attacker.totalWonSinceLastClaim + defenserRewards
            );
            dataContract.setTotalLostSinceLastClaim(
                _targetAddress,
                defenser.totalLostSinceLastClaim + defenserRewards
            );
            attackerStats[1]++;
            attackerStats[3] += defenserRewards;
            defenserStats[2]++;
            defenserStats[3] += defenserRewards;
            emit AttackResult(msg.sender, _targetAddress, msg.sender);
        } else {
            attackerStats[2]++;
            defenserStats[1]++;
            emit AttackResult(_targetAddress, msg.sender, msg.sender);
        }

        dataContract.setAttacksStats(msg.sender, attackerStats);
        dataContract.setDefensesStats(_targetAddress, defenserStats);
    }

    // Change the caller's username
    // _username: the username
    function changeUsername(string memory _username) external payable {
        require(msg.value >= changeUsernamePrice, "Not enough AVAX");
        bytes memory tempEmptyStringTest = bytes(_username);
        require(
            tempEmptyStringTest.length < 30,
            "Username too long. 30 characters max"
        );

        if (tempEmptyStringTest.length == 0) {
            dataContract.deleteUsernameForPlayer(msg.sender);
        } else {
            dataContract.setUsernameForPlayer(msg.sender, _username);
        }

        _sendFunds(msg.value);
    }

    // Set the boost provided by the Ades Blood upgrade
    // _boost: the boost value
    function adminSetAresBloodBoost(uint256 _boost) external onlyOwner {
        aresBloodBoost = _boost;
    }

    function adminSetgamePoolFee(uint256 _fee) external onlyOwner {
        gamePoolFee = _fee;
    }

    // Set Max ROI
    // _maxROI: number in %
    function adminSetMaxROI(uint256 _maxROI) external onlyOwner {
        maxROI = _maxROI;
    }

    // Set Max daily Avax per Share per day
    // _maxDailyAvaxPerShare: amount in ether
    function adminSetMaxDailyAvaxPerShare(uint256 _maxDailyAvaxPerShare)
        external
        onlyOwner
    {
        maxDailyAvaxPerShare = _maxDailyAvaxPerShare;
    }

    // Set the runway
    // _runwayInDays: value in days
    function adminSetRunwayInDays(uint256 _runwayInDays) external onlyOwner {
        runwayInDays = _runwayInDays;
    }

    // Set the number of epochs per day
    // _epochsPerDay: value
    function adminSetEpochsPerDay(uint256 _epochsPerDay) external onlyOwner {
        epochsPerDay = _epochsPerDay;
    }

    // Set the limit per player per upgrade tier
    // _tier: the tier value
    // _limit: the limit value
    function adminSetMaxUpgradesForTier(uint256 _tier, uint256 _limit)
        external
        onlyOwner
    {
        maxUpgradesPerTier[_tier] = _limit;
    }

    // Set the max supply per upgrade tier
    // _maxSupply: the max supply value
    // _tier: the tier value
    function adminSetWarriorsMaxSupplyForTier(uint256 _maxSupply, uint256 _tier)
        external
        onlyOwner
    {
        warriorsMaxSupplyTiers[_tier] = _maxSupply;
    }

    // Set the max supply per upgrade tier
    // _maxSupply: the max supply value
    // _tier: the tier value
    function adminSetDefensesMaxSupplyForTier(uint256 _maxSupply, uint256 _tier)
        external
        onlyOwner
    {
        defensesMaxSupplyTiers[_tier] = _maxSupply;
    }

    // Set the max supply per upgrade tier
    // _maxSupply: the max supply value
    // _tier: the tier value
    function adminSetUpgradesMaxSupplyForTier(uint256 _maxSupply, uint256 _tier)
        external
        onlyOwner
    {
        upgradesMaxSupplyTiers[_tier] = _maxSupply;
    }

    // Set the price of a tier
    // _price: the price in ether
    // _tier: the tier value
    function adminSetWarriorsAvaxPriceForTier(uint256 _price, uint256 _tier)
        external
        onlyOwner
    {
        warriorsAvaxPriceTiers[_tier] = _price;
    }

    // Set the price of a tier
    // _price: the price in ether
    // _tier: the tier value
    function adminSetDefensesAvaxPriceForTier(uint256 _price, uint256 _tier)
        external
        onlyOwner
    {
        defensesAvaxPriceTiers[_tier] = _price;
    }

    // Set the price of a tier
    // _price: the price in ether
    // _tier: the tier value
    function adminSetUpgradesAvaxPriceForTier(uint256 _price, uint256 _tier)
        external
        onlyOwner
    {
        upgradesAvaxPriceTiers[_tier] = _price;
    }

    // Change price of username change
    // _usernamePrice: price in ether
    function adminSetChangeUsernamePrice(uint256 _usernamePrice)
        external
        onlyOwner
    {
        changeUsernamePrice = _usernamePrice;
    }

    // Set the value of a tier for a building
    // _index: the index value
    // _value: the value
    function adminSetExcavatorValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        excavatorLevelValues[_index] = _value;
    }

    // Set the value of a tier for a building
    // _index: the index value
    // _value: the value
    function adminSetGarageValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        garageLevelValues[_index] = _value;
    }

    // Set the value of a tier for a building
    // _index: the index value
    // _value: the value
    function adminSetRadarValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        radarLevelValues[_index] = _value;
    }

    // Set the value of a tier for a building
    // _index: the index value
    // _value: the value
    function adminSetRobberySchoolValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        robberySchoolLevelValues[_index] = _value;
    }

    // Set the price of a tier for a building
    // _index: the index value
    // _value: the price in ether
    function adminSetExcavatorLevelPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        excavatorLevelPrices[_index] = _value;
    }

    // Set the price of a tier for a building
    // _index: the index value
    // _value: the price in ether
    function adminSetGaragePriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        garageLevelPrices[_index] = _value;
    }

    // Set the price of a tier for a building
    // _index: the index value
    // _value: the price in ether
    function adminSetRadarLevelPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        radarLevelPrices[_index] = _value;
    }

    // Set the price of a tier for a building
    // _index: the index value
    // _value: the price in ether
    function adminSetRobberySchoolLevelPriceForIndex(
        uint256 _index,
        uint256 _value
    ) external onlyOwner {
        robberySchoolLevelPrices[_index] = _value;
    }

    // Process an epoch and calculate the rewards to be distributed
    function adminProcessEpoch() external whenNotPaused onlyOwner {
        uint256 totalShares = dataContract.totalShares();

        uint256 avaxInPoolMinusRewards = dataContract
            .getPoolBalanceMinusRewards();
        uint256 ratioAvaxPerShare = avaxInPoolMinusRewards / totalShares;
        uint256 ratioAvaxPerSharePerDay = ratioAvaxPerShare / runwayInDays;

        // if the current ratio per share per day is higher than the max daily limit
        // forces the current ratio to max daily limit
        if (ratioAvaxPerSharePerDay > maxDailyAvaxPerShare) {
            ratioAvaxPerSharePerDay = maxDailyAvaxPerShare;
        }

        // divide rewards per number of epochs per day
        uint256 ratioAvaxPerSharePerEpoch = ratioAvaxPerSharePerDay /
            epochsPerDay;

        // Calculate total rewards for this epoch
        uint256 totalRewardsThisEpoch = ratioAvaxPerSharePerEpoch * totalShares;

        // If rewards are higher than what's in the pool
        // forces rewards to be what's left in the pool
        if (totalRewardsThisEpoch > avaxInPoolMinusRewards) {
            totalRewardsThisEpoch = avaxInPoolMinusRewards;
        }

        dataContract.setTotalRewardsPending(
            dataContract.totalRewardsPending() + totalRewardsThisEpoch
        );
        dataContract.setTotalRewards(
            dataContract.totalRewards() + totalRewardsThisEpoch
        );
        dataContract.setNextEpochTime(block.timestamp + (86400 / epochsPerDay));
        dataContract.createEpochSnapshot(
            block.timestamp,
            totalShares,
            totalRewardsThisEpoch
        );
    }

    // Get a player's rewards
    // _player: the player address
    function getPlayerRewards(address _player) public view returns (uint256) {
        // if player has ROI
        // forces rewards to only take avax won and lost in fights

        SharedStructs.Player memory player = dataContract.getPlayer(_player);
        if (player.isROI == true) {
            return
                player.totalWonSinceLastClaim - player.totalLostSinceLastClaim;
        }

        uint256 totalRewardsPerShare = 0;
        for (
            uint256 i = player.lastClaimEpoch;
            i < dataContract.currentEpoch();
            i++
        ) {
            SharedStructs.EpochSnapshot memory epoch = dataContract
                .getEpochSnapshot(i);
            totalRewardsPerShare += epoch.totalRewards / epoch.totalShares;
        }
        return
            (player.shares * totalRewardsPerShare) +
            player.totalWonSinceLastClaim -
            player.totalLostSinceLastClaim;
    }

    // Get the timestamp of when the player can attack again
    // _player: the player address
    function getAttackUnlocksTime(address _player)
        external
        view
        returns (uint256)
    {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);
        return player.attackUnlocksTime;
    }

    // Get the caller's warriors
    // returns an array of uint256
    function getPlayerBuildings(address _player)
        public
        view
        returns (uint256[10] memory)
    {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);
        return player.buildings;
    }

    // Get the caller's warriors
    // returns an array of uint256
    function getPlayerWarriors() external view returns (uint256[10] memory) {
        SharedStructs.Player memory player = dataContract.getPlayer(msg.sender);
        return player.warriorsByTier;
    }

    // Get the caller's defenses
    // returns an array of uint256
    function getPlayerDefenses() external view returns (uint256[10] memory) {
        SharedStructs.Player memory player = dataContract.getPlayer(msg.sender);
        return player.defensesByTier;
    }

    // Get the caller's upgrades
    // returns an array of uint256
    function getPlayerUpgrades() external view returns (uint256[10] memory) {
        SharedStructs.Player memory player = dataContract.getPlayer(msg.sender);
        return player.upgradesByTier;
    }

    // Return all Troops information
    function getTroopsInformation()
        external
        view
        returns (
            uint256[4] memory warriorsInUse,
            uint256[4] memory warriorsPrices,
            uint256[4] memory warriorsMaxSupply,
            uint256[4] memory defensesInUse,
            uint256[4] memory defensesPrices,
            uint256[4] memory defensesMaxSupply,
            uint256[2] memory upgradesInUse,
            uint256[2] memory upgradesPrices,
            uint256[2] memory upgradesMaxSupply,
            uint256[2] memory upgradesMaxPerTier
        )
    {
        warriorsInUse = warriorsInUseByTiers;
        warriorsPrices = warriorsAvaxPriceTiers;
        warriorsMaxSupply = warriorsMaxSupplyTiers;

        defensesInUse = defensesInUseByTiers;
        defensesPrices = defensesAvaxPriceTiers;
        defensesMaxSupply = defensesMaxSupplyTiers;

        upgradesInUse = upgradesInUseByTiers;
        upgradesPrices = upgradesAvaxPriceTiers;
        upgradesMaxSupply = upgradesMaxSupplyTiers;
        upgradesMaxPerTier = maxUpgradesPerTier;
    }

    // Return all Buildings information
    function getBuildingsInformation()
        external
        view
        returns (
            uint256[4] memory excavatorLevels,
            uint256[3] memory excavatorPrices,
            uint256[6] memory garageLevels,
            uint256[5] memory garagePrices,
            uint256[2] memory radarLevels,
            uint256[1] memory radarPrices,
            uint256[7] memory robberySchoolLevels,
            uint256[6] memory robberySchoolPrices
        )
    {
        excavatorLevels = excavatorLevelValues;
        excavatorPrices = excavatorLevelPrices;

        garageLevels = garageLevelValues;
        garagePrices = garageLevelPrices;

        radarLevels = radarLevelValues;
        radarPrices = radarLevelPrices;

        robberySchoolLevels = robberySchoolLevelValues;
        robberySchoolPrices = robberySchoolLevelPrices;
    }

    // Get the list of players in a tier
    // _tier: the tier value
    function getPlayersInTier(uint256 _minRange, uint256 _maxRange)
        external
        view
        returns (PlayerInTier[] memory)
    {
        // Get the number of player in the tier
        uint256 playerCounts = 0;
        for (uint256 i = _minRange; i <= _maxRange; i++) {
            playerCounts += dataContract.playersInTiers(i);
        }

        PlayerInTier[] memory playersInTier = new PlayerInTier[](playerCounts);
        uint256 y = 0;

        // Loop over all players
        for (
            uint256 i = 0;
            i < dataContract.getPlayersAddresses().length;
            i++
        ) {
            address playerAddress = dataContract.getPlayerAddress(i);
            SharedStructs.Player memory player = dataContract.getPlayer(
                playerAddress
            );
            // Verify that the player isn't the caller and that the player is in the same tier

            if ((player.tier >= _minRange && player.tier <= _maxRange)) {
                PlayerInTier memory pit = PlayerInTier(
                    playerAddress,
                    dataContract.playersToUsername(playerAddress),
                    getPlayerRewards(playerAddress),
                    player.defensePower,
                    dataContract.getPlayer(msg.sender).buildings[2] > 0
                        ? player.upgradesByTier[0]
                        : 0
                );
                playersInTier[y] = pit;
                y++;
            }
        }
        return playersInTier;
    }

    // Verify all requirements before recruiting troops
    // _type: the type of troop (warrior, defense or upgrade)
    // _tier: the tier of troops
    // _qty: the quantity of troops being recruited
    // _player: the buyer address
    // _promotional: is it a gift
    function _recruitRequires(
        uint256 _type,
        uint256 _tier,
        uint256 _qty,
        address _player,
        address _referrer,
        bool _promotional
    ) private {
        require(_type >= 0 && _type <= 2, "Invalid type");
        require(_qty > 0, "Invalid count of troop to recruit");
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(
            _referrer == address(0) ||
                (_referrer != address(0) &&
                    dataContract.getPlayer(_referrer).shares > 0),
            "Referrer has no shares"
        );

        if (_type == 0) {
            require(
                _tier >= 0 && _tier <= 3,
                "Invalid tier. Valid range: 0 to 3"
            );
            require(
                warriorsInUseByTiers[_tier] + _qty <=
                    warriorsMaxSupplyTiers[_tier],
                "Max Supply reached for this tier"
            );
            if (!_promotional) {
                require(
                    msg.value >= warriorsAvaxPriceTiers[_tier] * _qty,
                    "Not enough AVAX"
                );
            }
        } else if (_type == 1) {
            require(
                _tier >= 0 && _tier <= 3,
                "Invalid tier. Valid range: 0 to 3"
            );
            require(
                defensesInUseByTiers[_tier] + _qty <=
                    defensesMaxSupplyTiers[_tier],
                "Max Supply reached for this tier"
            );
            if (!_promotional) {
                require(
                    msg.value >= defensesAvaxPriceTiers[_tier] * _qty,
                    "Not enough AVAX"
                );
            }
        } else if (_type == 2) {
            require(
                _tier >= 0 && _tier <= 1,
                "Invalid tier. Valid range: 0 to 1"
            );
            require(
                upgradesInUseByTiers[_tier] + _qty <=
                    upgradesMaxSupplyTiers[_tier],
                "Max Supply reached for this tier"
            );
            require(
                dataContract.getPlayer(_player).upgradesByTier[_tier] + _qty <=
                    maxUpgradesPerTier[_tier],
                "Above limit for this upgrade tier"
            );
            if (!_promotional) {
                require(
                    msg.value >= upgradesAvaxPriceTiers[_tier] * _qty,
                    "Not enough AVAX"
                );
            }
        }
    }

    // Gift troops
    // _type: the type of troop (warrior, defense, upgrade)
    // _tier: the tier of the troop
    // _qty: the quantity to buy
    // _player: the buyer address
    function adminGiftRecruitTroops(
        uint256 _type,
        uint256 _tier,
        uint256 _qty,
        address _player
    ) external onlyOwner {
        _recruitRequires(_type, _tier, _qty, _player, address(0), true);

        if (_type == 0) {
            _recruitWarriors(_tier, _qty, _player);
        } else if (_type == 1) {
            _recruitDefenses(_tier, _qty, _player);
        } else if (_type == 2) {
            _recruitUpgrades(_tier, _qty, _player);
        }
    }

    error FailedToSendEther();

    // Recruit troops
    // _type: the type of troop (warrior, defense, upgrade)
    // _tier: the tier of the troop
    // _qty: the quantity to buy
    function recruitTroops(
        uint256 _type,
        uint256 _tier,
        uint256 _qty,
        address _referrer
    ) external payable whenNotPaused {
        _recruitRequires(_type, _tier, _qty, msg.sender, _referrer, false);

        _claim(msg.sender);
        if (_type == 0) {
            _recruitWarriors(_tier, _qty, msg.sender);
        } else if (_type == 1) {
            _recruitDefenses(_tier, _qty, msg.sender);
        } else if (_type == 2) {
            _recruitUpgrades(_tier, _qty, msg.sender);
        }

        if (_referrer != address(0)) {
            uint256 freeShares = msg.value / 2500000000000000000;
            _recruitWarriors(0, freeShares, _referrer);
        }

        _sendFunds(msg.value);
    }

    // Buy Warriors
    // _tier: the tier of the troop
    // _qty: the quantity to buy
    // _player: the buyer address
    function _recruitWarriors(
        uint256 _tier,
        uint256 _qty,
        address _player
    ) private {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);

        warriorsInUseByTiers[_tier] += _qty;

        uint256 additionalAttackPower = (warriorsSharesTiers[_tier] * _qty);

        dataContract.setWarriorsByTier(
            _player,
            _tier,
            player.warriorsByTier[_tier] + _qty
        );
        dataContract.setAttackPower(
            _player,
            player.attackPower + additionalAttackPower
        );
        dataContract.setShares(_player, player.shares + additionalAttackPower);

        // Reset its ROI value
        // and adds back its shares to the total shares
        if (player.isROI) {
            dataContract.setIsROI(_player, false);
            dataContract.setTotalShares(
                dataContract.totalShares() +
                    player.shares +
                    additionalAttackPower
            );
        } else {
            dataContract.setTotalShares(
                dataContract.totalShares() + additionalAttackPower
            );
        }

        _checkNewPlayer(player, _player);
    }

    function _checkNewPlayer(
        SharedStructs.Player memory player,
        address _player
    ) private {
        // if new player
        // creates a new player, adds the address to the list of players
        if (player.attackUnlocksTime == 0) {
            dataContract.addNewAddress(_player);
            dataContract.updatePlayerLastClaimEpoch(_player);
            dataContract.setAttackUnlocksTime(_player, block.timestamp);
            _setTierForPlayer(_player, true);
        } else {
            _setTierForPlayer(_player, false);
        }
    }

    // Set the tier of a player
    // _player: the player address
    // isNewPlayer: defines if the player is new to the game
    function _setTierForPlayer(address _player, bool _isNewPlayer) private {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);
        uint256 playerShare = player.shares;
        for (uint256 i = 0; i < ranks.length; i++) {
            // Verify in which tier the player should be based on its shares
            if (
                i == ranks.length ||
                (playerShare >= ranks[i] && playerShare < ranks[i + 1])
            ) {
                dataContract.setTier(_player, _isNewPlayer, i);
                break;
            }
        }
    }

    // Set Ranks ranges
    function adminSetRanks(uint256[] calldata _ranks) external onlyOwner {
        ranks = _ranks;
    }

    // Buy Defenses
    // _tier: the tier of the troop
    // _qty: the quantity to buy
    // _player: the buyer address
    function _recruitDefenses(
        uint256 _tier,
        uint256 _qty,
        address _player
    ) private {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);

        defensesInUseByTiers[_tier] += _qty;

        uint256 additionalDefensePower = defensesSharesTiers[_tier] * _qty;

        dataContract.setDefensesByTier(
            _player,
            _tier,
            player.defensesByTier[_tier] + _qty
        );
        dataContract.setDefensePower(
            _player,
            player.defensePower + additionalDefensePower
        );
        dataContract.setShares(_player, player.shares + additionalDefensePower);

        // Reset its ROI value
        // and adds back its shares to the total shares
        if (player.isROI) {
            dataContract.setIsROI(_player, false);
            dataContract.setTotalShares(
                dataContract.totalShares() +
                    player.shares +
                    additionalDefensePower
            );
        } else {
            dataContract.setTotalShares(
                dataContract.totalShares() + additionalDefensePower
            );
        }

        _checkNewPlayer(player, _player);
    }

    // Buy Upgrades
    // _tier: the tier of the troop
    // _qty: the quantity to buy
    // _player: the buyer address
    function _recruitUpgrades(
        uint256 _tier,
        uint256 _qty,
        address _player
    ) private {
        SharedStructs.Player memory player = dataContract.getPlayer(_player);

        upgradesInUseByTiers[_tier] += _qty;
        dataContract.setUpgradesByTier(
            _player,
            _tier,
            player.upgradesByTier[_tier] + _qty
        );

        // if buying an hydra
        if (_tier == 0) {
            dataContract.setShares(
                _player,
                player.shares + (upgradesSharesTiers[_tier] * _qty)
            );

            // If the buyer has ROId
            // Reset its ROI value
            // and adds back its shares to the total shares
            if (player.isROI) {
                dataContract.setIsROI(_player, false);
                dataContract.setTotalShares(
                    dataContract.totalShares() +
                        player.shares +
                        (upgradesSharesTiers[_tier] * _qty)
                );
            } else {
                dataContract.setTotalShares(
                    dataContract.totalShares() +
                        (upgradesSharesTiers[_tier] * _qty)
                );
            }
        }

        _checkNewPlayer(player, _player);
    }

    // Claim rewards
    // _player: the claimer address
    function _claim(address _player) private {
        SharedStructs.Player memory player = dataContract.getPlayer(msg.sender);

        // Claim timing check
        if (
            player.lastClaimEpoch != dataContract.currentEpoch() &&
            player.nextClaimTime < block.timestamp
        ) {
            uint256 rewards = getPlayerRewards(_player);
            if (rewards > dataContract.getPoolBalanceMinusRewards()) {
                rewards = dataContract.getPoolBalanceMinusRewards();
            }

            // Verify if the user is going over ROI on this claim
            if (
                player.shares != 0 &&
                (rewards + player.totalClaimed >
                    ((player.shares * maxROI * MULTIPLIER) / 100))
            ) {
                dataContract.setIsROI(msg.sender, true);
                // decrement totalShares so player is out of calculation in rewards of each epoch
                dataContract.setTotalShares(
                    dataContract.totalShares() - player.shares
                );
                // forces rewards to be what the user can claim to reach max ROI
                rewards =
                    ((player.shares * maxROI * MULTIPLIER) / 100) -
                    player.totalClaimed;
            }

            dataContract.claimForPlayer(
                msg.sender,
                rewards,
                block.timestamp + excavatorLevelValues[player.buildings[0]]
            );
        }
    }

    // Claim rewards
    // _player: the claimer address
    function claimRewards() external whenNotPaused {
        SharedStructs.Player memory player = dataContract.getPlayer(msg.sender);
        require(player.nextClaimTime < block.timestamp, "Cannot claim yet");
        require(player.shares > 0, "No share");

        _claim(msg.sender);
    }

    function getPlayer() external view returns (SharedStructs.Player memory) {
        return dataContract.getPlayer(msg.sender);
    }

    function checkReferrer(address _address) external view returns (bool) {
        return dataContract.getPlayer(_address).shares > 0;
    }
}