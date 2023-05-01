// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {BaseAbstract} from "./BaseAbstract.sol";
import {Storage} from "./Storage.sol";

abstract contract Base is BaseAbstract {
	/// @dev Set the main GoGo Storage address
	constructor(Storage _gogoStorageAddress) {
		// Update the contract address
		gogoStorage = Storage(_gogoStorageAddress);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Storage} from "./Storage.sol";

/// @title Base contract for network contracts
abstract contract BaseAbstract {
	error InvalidOrOutdatedContract();
	error MustBeGuardian();
	error MustBeMultisig();
	error ContractPaused();
	error ContractNotFound();
	error MustBeGuardianOrValidContract();

	uint8 public version;

	Storage internal gogoStorage;

	/// @dev Verify caller is a registered network contract
	modifier onlyRegisteredNetworkContract() {
		if (getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))) == false) {
			revert InvalidOrOutdatedContract();
		}
		_;
	}

	/// @dev Verify caller is registered version of `contractName`
	modifier onlySpecificRegisteredContract(string memory contractName, address contractAddress) {
		if (contractAddress != getAddress(keccak256(abi.encodePacked("contract.address", contractName)))) {
			revert InvalidOrOutdatedContract();
		}
		_;
	}

	/// @dev Verify caller is a guardian or registered network contract
	modifier guardianOrRegisteredContract() {
		bool isContract = getBool(keccak256(abi.encodePacked("contract.exists", msg.sender)));
		bool isGuardian = msg.sender == gogoStorage.getGuardian();

		if (!(isGuardian || isContract)) {
			revert MustBeGuardianOrValidContract();
		}
		_;
	}

	/// @dev Verify caller is a guardian or registered version of `contractName`
	modifier guardianOrSpecificRegisteredContract(string memory contractName, address contractAddress) {
		bool isContract = contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", contractName)));
		bool isGuardian = msg.sender == gogoStorage.getGuardian();

		if (!(isGuardian || isContract)) {
			revert MustBeGuardianOrValidContract();
		}
		_;
	}

	/// @dev Verify caller is the guardian
	modifier onlyGuardian() {
		if (msg.sender != gogoStorage.getGuardian()) {
			revert MustBeGuardian();
		}
		_;
	}

	/// @dev Verify caller is a valid multisig
	modifier onlyMultisig() {
		int256 multisigIndex = int256(getUint(keccak256(abi.encodePacked("multisig.index", msg.sender)))) - 1;
		address addr = getAddress(keccak256(abi.encodePacked("multisig.item", multisigIndex, ".address")));
		bool enabled = (addr != address(0)) && getBool(keccak256(abi.encodePacked("multisig.item", multisigIndex, ".enabled")));
		if (enabled == false) {
			revert MustBeMultisig();
		}
		_;
	}

	/// @dev Verify contract is not paused
	modifier whenNotPaused() {
		string memory contractName = getContractName(address(this));
		if (getBool(keccak256(abi.encodePacked("contract.paused", contractName)))) {
			revert ContractPaused();
		}
		_;
	}

	/// @dev Get the address of a network contract by name
	function getContractAddress(string memory contractName) internal view returns (address) {
		address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", contractName)));
		if (contractAddress == address(0x0)) {
			revert ContractNotFound();
		}
		return contractAddress;
	}

	/// @dev Get the name of a network contract by address
	function getContractName(address contractAddress) internal view returns (string memory) {
		string memory contractName = getString(keccak256(abi.encodePacked("contract.name", contractAddress)));
		if (bytes(contractName).length == 0) {
			revert ContractNotFound();
		}
		return contractName;
	}

	function getAddress(bytes32 key) internal view returns (address) {
		return gogoStorage.getAddress(key);
	}

	function getBool(bytes32 key) internal view returns (bool) {
		return gogoStorage.getBool(key);
	}

	function getBytes(bytes32 key) internal view returns (bytes memory) {
		return gogoStorage.getBytes(key);
	}

	function getBytes32(bytes32 key) internal view returns (bytes32) {
		return gogoStorage.getBytes32(key);
	}

	function getInt(bytes32 key) internal view returns (int256) {
		return gogoStorage.getInt(key);
	}

	function getUint(bytes32 key) internal view returns (uint256) {
		return gogoStorage.getUint(key);
	}

	function getString(bytes32 key) internal view returns (string memory) {
		return gogoStorage.getString(key);
	}

	function setAddress(bytes32 key, address value) internal {
		gogoStorage.setAddress(key, value);
	}

	function setBool(bytes32 key, bool value) internal {
		gogoStorage.setBool(key, value);
	}

	function setBytes(bytes32 key, bytes memory value) internal {
		gogoStorage.setBytes(key, value);
	}

	function setBytes32(bytes32 key, bytes32 value) internal {
		gogoStorage.setBytes32(key, value);
	}

	function setInt(bytes32 key, int256 value) internal {
		gogoStorage.setInt(key, value);
	}

	function setUint(bytes32 key, uint256 value) internal {
		gogoStorage.setUint(key, value);
	}

	function setString(bytes32 key, string memory value) internal {
		gogoStorage.setString(key, value);
	}

	function deleteAddress(bytes32 key) internal {
		gogoStorage.deleteAddress(key);
	}

	function deleteBool(bytes32 key) internal {
		gogoStorage.deleteBool(key);
	}

	function deleteBytes(bytes32 key) internal {
		gogoStorage.deleteBytes(key);
	}

	function deleteBytes32(bytes32 key) internal {
		gogoStorage.deleteBytes32(key);
	}

	function deleteInt(bytes32 key) internal {
		gogoStorage.deleteInt(key);
	}

	function deleteUint(bytes32 key) internal {
		gogoStorage.deleteUint(key);
	}

	function deleteString(bytes32 key) internal {
		gogoStorage.deleteString(key);
	}

	function addUint(bytes32 key, uint256 amount) internal {
		gogoStorage.addUint(key, amount);
	}

	function subUint(bytes32 key, uint256 amount) internal {
		gogoStorage.subUint(key, amount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {BaseAbstract} from "./BaseAbstract.sol";
import {Storage} from "./Storage.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BaseUpgradeable is Initializable, BaseAbstract {
	function __BaseUpgradeable_init(Storage gogoStorageAddress) internal onlyInitializing {
		gogoStorage = Storage(gogoStorageAddress);
	}

	/// @dev This empty reserved space is put in place to allow future versions to add new
	/// variables without shifting down storage in the inheritance chain.
	uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Base} from "./Base.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";
import {Storage} from "./Storage.sol";

/// @title Settings for the Protocol
contract ProtocolDAO is Base {
	error ContractAlreadyRegistered();
	error ExistingContractNotRegistered();
	error InvalidContract();
	error ValueNotWithinRange();

	modifier valueNotGreaterThanOne(uint256 setterValue) {
		if (setterValue > 1 ether) {
			revert ValueNotWithinRange();
		}
		_;
	}

	constructor(Storage storageAddress) Base(storageAddress) {
		version = 1;
	}

	function initialize() external onlyGuardian {
		if (getBool(keccak256("ProtocolDAO.initialized"))) {
			return;
		}
		setBool(keccak256("ProtocolDAO.initialized"), true);

		// ClaimNodeOp
		setUint(keccak256("ProtocolDAO.RewardsEligibilityMinSeconds"), 14 days);

		// RewardsPool
		setUint(keccak256("ProtocolDAO.RewardsCycleSeconds"), 28 days); // The time in which a claim period will span in seconds - 28 days by default
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.MultisigManager"), 0.10 ether);
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimNodeOp"), 0.70 ether);
		setUint(keccak256("ProtocolDAO.ClaimingContractPct.ClaimProtocolDAO"), 0.20 ether);

		// GGP Inflation
		setUint(keccak256("ProtocolDAO.InflationIntervalSeconds"), 1 days);
		setUint(keccak256("ProtocolDAO.InflationIntervalRate"), 1000133680617113500); // 5% annual calculated on a daily interval - Calculate in js example: let dailyInflation = web3.utils.toBN((1 + 0.05) ** (1 / (365)) * 1e18);

		// TokenGGAVAX
		setUint(keccak256("ProtocolDAO.TargetGGAVAXReserveRate"), 0.1 ether); // 10% collateral held in reserve

		// Minipool
		setUint(keccak256("ProtocolDAO.MinipoolMinAVAXStakingAmt"), 2_000 ether);
		setUint(keccak256("ProtocolDAO.MinipoolNodeCommissionFeePct"), 0.15 ether);
		setUint(keccak256("ProtocolDAO.MinipoolMinDuration"), 14 days);
		setUint(keccak256("ProtocolDAO.MinipoolMaxDuration"), 365 days);
		setUint(keccak256("ProtocolDAO.MinipoolCycleDuration"), 14 days);
		setUint(keccak256("ProtocolDAO.MinipoolCycleDelayTolerance"), 1 days);
		setUint(keccak256("ProtocolDAO.MinipoolMaxAVAXAssignment"), 1_000 ether);
		setUint(keccak256("ProtocolDAO.MinipoolMinAVAXAssignment"), 1_000 ether);
		setUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"), 0.1 ether); // Annual rate as pct of 1 avax
		setUint(keccak256("ProtocolDAO.MinipoolCancelMoratoriumSeconds"), 5 days);

		// Staking
		setUint(keccak256("ProtocolDAO.MaxCollateralizationRatio"), 1.5 ether);
		setUint(keccak256("ProtocolDAO.MinCollateralizationRatio"), 0.1 ether);
	}

	/// @notice Get if a contract is paused
	/// @param contractName The contract that is being checked
	/// @return boolean representing if the contract passed in is paused
	function getContractPaused(string memory contractName) public view returns (bool) {
		return getBool(keccak256(abi.encodePacked("contract.paused", contractName)));
	}

	/// @notice Pause a contract
	/// @param contractName The contract whose actions should be paused
	function pauseContract(string memory contractName) public onlySpecificRegisteredContract("Ocyticus", msg.sender) {
		setBool(keccak256(abi.encodePacked("contract.paused", contractName)), true);
	}

	/// @notice Unpause a contract
	/// @param contractName The contract whose actions should be resumed
	function resumeContract(string memory contractName) public onlySpecificRegisteredContract("Ocyticus", msg.sender) {
		setBool(keccak256(abi.encodePacked("contract.paused", contractName)), false);
	}

	// *** Rewards Pool ***

	/// @notice Get how many seconds a node must be registered for rewards to be eligible for the rewards cycle
	/// @return uint256 The min number of seconds to be considered eligible
	function getRewardsEligibilityMinSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.RewardsEligibilityMinSeconds"));
	}

	/// @notice Get how many seconds in a rewards cycle
	/// @return The setting for the rewards cycle length in seconds
	function getRewardsCycleSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.RewardsCycleSeconds"));
	}

	/// @notice The percentage a contract is owed for a rewards cycle
	/// @param claimingContract The name of the the claiming contract
	/// @return uint256 Rewards percentage the passed in contract will receive this cycle
	function getClaimingContractPct(string memory claimingContract) public view returns (uint256) {
		return getUint(keccak256(abi.encodePacked("ProtocolDAO.ClaimingContractPct.", claimingContract)));
	}

	/// @notice Set the percentage a contract is owed for a rewards cycle
	/// @param claimingContract The name of the claiming contract
	/// @param decimal A decimal representing a percentage of the rewards that the claiming contract is due
	function setClaimingContractPct(string memory claimingContract, uint256 decimal) public onlyGuardian valueNotGreaterThanOne(decimal) {
		setUint(keccak256(abi.encodePacked("ProtocolDAO.ClaimingContractPct.", claimingContract)), decimal);
	}

	// *** GGP Inflation ***

	/// @notice The current inflation rate per interval (eg 1000133680617113500 = 5% annual)
	/// @return uint256 The current inflation rate per interval (can never be < 1 ether)
	function getInflationIntervalRate() external view returns (uint256) {
		// Inflation rate controlled by the DAO
		uint256 rate = getUint(keccak256("ProtocolDAO.InflationIntervalRate"));
		return rate < 1 ether ? 1 ether : rate;
	}

	/// @notice How many seconds to calculate inflation at
	/// @return uint256 how many seconds to calculate inflation at
	function getInflationIntervalSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.InflationIntervalSeconds"));
	}

	// *** Minipool Settings ***

	/// @notice The min AVAX staking amount that is required for creating a minipool
	/// @return The protocol's setting for a minipool's min AVAX staking requirement
	function getMinipoolMinAVAXStakingAmt() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMinAVAXStakingAmt"));
	}

	/// @notice The node commission fee for running the hardware for the minipool
	/// @return The protocol setting for a percentage that a minipool's node gets as a commission fee
	function getMinipoolNodeCommissionFeePct() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolNodeCommissionFeePct"));
	}

	/// @notice Maximum AVAX a Node Operator can be assigned from liquid staking funds
	/// @return The protocol setting for a minipool's max AVAX assignment from liquids staking funds
	function getMinipoolMaxAVAXAssignment() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMaxAVAXAssignment"));
	}

	/// @notice Minimum AVAX a Node Operator can be assigned from liquid staking funds
	/// @return The protocol setting for a minipool's min AVAX assignment from liquids staking funds
	function getMinipoolMinAVAXAssignment() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMinAVAXAssignment"));
	}

	/// @notice The user must wait this amount of time before they can cancel their minipool
	/// @return The protocol setting for the amount of time a user must wait before they can cancel a minipool in seconds
	function getMinipoolCancelMoratoriumSeconds() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolCancelMoratoriumSeconds"));
	}

	/// @notice Min duration a minipool can be live for
	/// @return The protocol setting for the min duration a minipool can stake in days
	function getMinipoolMinDuration() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMinDuration"));
	}

	/// @notice Max duration a minipool can be live for
	/// @return The protocol setting for the max duration a minipool can stake in days
	function getMinipoolMaxDuration() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolMaxDuration"));
	}

	/// @notice The duration of a cycle for a minipool
	/// @return The protocol setting for length of time a minipool cycle is in days
	function getMinipoolCycleDuration() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolCycleDuration"));
	}

	/// @notice The duration of a minipool's cycle delay tolerance
	/// @return The protocol setting for length of time a minipool cycle can be delayed in days
	function getMinipoolCycleDelayTolerance() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinipoolCycleDelayTolerance"));
	}

	/// @notice Set the rewards rate for validating Avalanche's p-chain
	/// @param rate A percentage representing Avalanche's rewards rate
	/// @dev Used for testing
	function setExpectedAVAXRewardsRate(uint256 rate) public onlyMultisig valueNotGreaterThanOne(rate) {
		setUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"), rate);
	}

	/// @notice The expected rewards rate for validating Avalanche's P-chain
	/// @return The protocol setting for the average rewards rate a node receives for being a validator
	function getExpectedAVAXRewardsRate() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.ExpectedAVAXRewardsRate"));
	}

	//*** Staking ***

	/// @notice The target percentage of ggAVAX to hold in TokenggAVAX contract
	/// 	1 ether = 100%
	/// 	0.1 ether = 10%
	/// @return uint256 The protocol setting for the current target reserve rate
	function getTargetGGAVAXReserveRate() external view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.TargetGGAVAXReserveRate"));
	}

	/// @notice The max collateralization ratio of GGP to Assigned AVAX eligible for rewards
	/// @return The protocol setting for the max collateralization ratio of GGP to assigned AVAX a user can be rewarded for
	function getMaxCollateralizationRatio() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MaxCollateralizationRatio"));
	}

	/// @notice The min collateralization ratio of GGP to Assigned AVAX eligible for rewards or minipool creation
	/// @return The protocol setting for the min collateralization ratio of GGP to assigned AVAX a user can borrow at
	function getMinCollateralizationRatio() public view returns (uint256) {
		return getUint(keccak256("ProtocolDAO.MinCollateralizationRatio"));
	}

	//*** Contract Registration ***

	/// @notice Upgrade a contract by registering a new address and name, and un-registering the existing address
	/// @param contractName Name of the new contract
	/// @param existingAddr Address of the existing contract to be deleted
	/// @param newAddr Address of the new contract
	function upgradeContract(string memory contractName, address existingAddr, address newAddr) external onlyGuardian {
		if (
			bytes(getString(keccak256(abi.encodePacked("contract.name", existingAddr)))).length == 0 ||
			getAddress(keccak256(abi.encodePacked("contract.address", contractName))) == address(0)
		) {
			revert ExistingContractNotRegistered();
		}

		if (newAddr == address(0)) {
			revert InvalidContract();
		}

		setAddress(keccak256(abi.encodePacked("contract.address", contractName)), newAddr);
		setString(keccak256(abi.encodePacked("contract.name", newAddr)), contractName);
		setBool(keccak256(abi.encodePacked("contract.exists", newAddr)), true);

		deleteString(keccak256(abi.encodePacked("contract.name", existingAddr)));
		deleteBool(keccak256(abi.encodePacked("contract.exists", existingAddr)));
	}

	/// @notice Register a new contract with Storage
	/// @param contractName Contract name to register
	/// @param contractAddr Contract address to register
	function registerContract(string memory contractName, address contractAddr) public onlyGuardian {
		if (getAddress(keccak256(abi.encodePacked("contract.address", contractName))) != address(0)) {
			revert ContractAlreadyRegistered();
		}

		if (bytes(contractName).length == 0 || contractAddr == address(0)) {
			revert InvalidContract();
		}

		setBool(keccak256(abi.encodePacked("contract.exists", contractAddr)), true);
		setAddress(keccak256(abi.encodePacked("contract.address", contractName)), contractAddr);
		setString(keccak256(abi.encodePacked("contract.name", contractAddr)), contractName);
	}

	/// @notice Unregister a contract with Storage
	/// @param name Name of contract to unregister
	function unregisterContract(string memory name) public onlyGuardian {
		address addr = getContractAddress(name);
		deleteAddress(keccak256(abi.encodePacked("contract.address", name)));
		deleteString(keccak256(abi.encodePacked("contract.name", addr)));
		deleteBool(keccak256(abi.encodePacked("contract.exists", addr)));
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @title The primary persistent storage for GoGoPool
/// Based on RocketStorage by RocketPool

contract Storage {
	error InvalidGuardianConfirmation();
	error InvalidOrOutdatedContract();
	error MustBeGuardian();
	error InvalidGuardianAddress();

	event GuardianChanged(address oldGuardian, address newGuardian);

	// Storage maps
	mapping(bytes32 => address) private addressStorage;
	mapping(bytes32 => bool) private booleanStorage;
	mapping(bytes32 => bytes) private bytesStorage;
	mapping(bytes32 => bytes32) private bytes32Storage;
	mapping(bytes32 => int256) private intStorage;
	mapping(bytes32 => string) private stringStorage;
	mapping(bytes32 => uint256) private uintStorage;

	// Guardian address
	address private guardian;
	address public newGuardian;

	/// @dev Only allow access from guardian or the latest version of a contract in the GoGoPool network
	modifier onlyGuardianOrRegisteredNetworkContract() {
		if (booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))] == false && msg.sender != guardian) {
			revert InvalidOrOutdatedContract();
		}
		_;
	}

	/// @dev This contract will be deployed via create2 proxy, so msg.sender will not work.
	constructor() {
		emit GuardianChanged(address(0), tx.origin);
		guardian = tx.origin;
	}

	/// @notice Initiates the transfer of guardianship to a new address
	/// @param newAddress The address that will become the guardian of the protocol
	function setGuardian(address newAddress) external {
		// Check tx comes from current guardian
		if (msg.sender != guardian) {
			revert MustBeGuardian();
		}
		if (newAddress == address(0x0)) {
			revert InvalidGuardianAddress();
		}
		// Store new address awaiting confirmation
		newGuardian = newAddress;
		emit GuardianChanged(guardian, newGuardian);
	}

	/// @notice Get the protocol's guardian address
	/// @return The C-chain address for the guardian of the protocol
	function getGuardian() external view returns (address) {
		return guardian;
	}

	/// @notice Completes the transfer of guardianship
	function confirmGuardian() external {
		if (msg.sender != newGuardian) {
			revert InvalidGuardianConfirmation();
		}
		// Store old guardian for event
		address oldGuardian = guardian;
		// Update guardian and clear storage
		guardian = newGuardian;
		delete newGuardian;
		emit GuardianChanged(oldGuardian, guardian);
	}

	//
	// GET
	//

	function getAddress(bytes32 key) external view returns (address) {
		return addressStorage[key];
	}

	function getBool(bytes32 key) external view returns (bool) {
		return booleanStorage[key];
	}

	function getBytes(bytes32 key) external view returns (bytes memory) {
		return bytesStorage[key];
	}

	function getBytes32(bytes32 key) external view returns (bytes32) {
		return bytes32Storage[key];
	}

	function getInt(bytes32 key) external view returns (int256) {
		return intStorage[key];
	}

	function getString(bytes32 key) external view returns (string memory) {
		return stringStorage[key];
	}

	function getUint(bytes32 key) external view returns (uint256) {
		return uintStorage[key];
	}

	//
	// SET
	//

	function setAddress(bytes32 key, address value) external onlyGuardianOrRegisteredNetworkContract {
		addressStorage[key] = value;
	}

	function setBool(bytes32 key, bool value) external onlyGuardianOrRegisteredNetworkContract {
		booleanStorage[key] = value;
	}

	function setBytes(bytes32 key, bytes calldata value) external onlyGuardianOrRegisteredNetworkContract {
		bytesStorage[key] = value;
	}

	function setBytes32(bytes32 key, bytes32 value) external onlyGuardianOrRegisteredNetworkContract {
		bytes32Storage[key] = value;
	}

	function setInt(bytes32 key, int256 value) external onlyGuardianOrRegisteredNetworkContract {
		intStorage[key] = value;
	}

	function setString(bytes32 key, string calldata value) external onlyGuardianOrRegisteredNetworkContract {
		stringStorage[key] = value;
	}

	function setUint(bytes32 key, uint256 value) external onlyGuardianOrRegisteredNetworkContract {
		uintStorage[key] = value;
	}

	//
	// DELETE
	//

	function deleteAddress(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete addressStorage[key];
	}

	function deleteBool(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete booleanStorage[key];
	}

	function deleteBytes(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete bytesStorage[key];
	}

	function deleteBytes32(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete bytes32Storage[key];
	}

	function deleteInt(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete intStorage[key];
	}

	function deleteString(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete stringStorage[key];
	}

	function deleteUint(bytes32 key) external onlyGuardianOrRegisteredNetworkContract {
		delete uintStorage[key];
	}

	//
	// ADD / SUBTRACT HELPERS
	//

	/// @notice Add to a uint
	/// @param key The key for the record
	/// @param amount An amount to add to the record's value
	function addUint(bytes32 key, uint256 amount) external onlyGuardianOrRegisteredNetworkContract {
		uintStorage[key] = uintStorage[key] + amount;
	}

	/// @notice Subtract from a uint
	/// @param key The key for the record
	/// @param amount An amount to subtract from the record's value
	function subUint(bytes32 key, uint256 amount) external onlyGuardianOrRegisteredNetworkContract {
		uintStorage[key] = uintStorage[key] - amount;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Base} from "./Base.sol";
import {IWithdrawer} from "../interface/IWithdrawer.sol";
import {Storage} from "./Storage.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";
import {WAVAX} from "./utils/WAVAX.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

// !!!WARNING!!! The Vault contract must not be upgraded
// AVAX and ggAVAX are stored here to prevent contract upgrades from affecting balances
// based on RocketVault by RocketPool

/// @notice Vault and ledger for AVAX and tokens
contract Vault is Base, ReentrancyGuard {
	using SafeTransferLib for ERC20;
	using SafeTransferLib for address;

	error InsufficientContractBalance();
	error InvalidAmount();
	error InvalidToken();
	error InvalidNetworkContract();
	error TokenTransferFailed();
	error VaultTokenWithdrawalFailed();

	event AVAXDeposited(string indexed by, uint256 amount);
	event AVAXTransfer(string indexed from, string indexed to, uint256 amount);
	event AVAXWithdrawn(string indexed by, uint256 amount);
	event TokenDeposited(bytes32 indexed by, address indexed tokenAddress, uint256 amount);
	event TokenTransfer(bytes32 indexed by, bytes32 indexed to, address indexed tokenAddress, uint256 amount);
	event TokenWithdrawn(bytes32 indexed by, address indexed tokenAddress, uint256 amount);

	mapping(string => uint256) private avaxBalances;
	mapping(bytes32 => uint256) private tokenBalances;
	mapping(address => bool) private allowedTokens;

	constructor(Storage storageAddress) Base(storageAddress) {
		version = 1;
	}

	/// @notice Accept an AVAX deposit from a network contract
	function depositAVAX() external payable onlyRegisteredNetworkContract {
		// Valid Amount?
		if (msg.value == 0) {
			revert InvalidAmount();
		}
		// Get contract name
		string memory contractName = getContractName(msg.sender);
		// Emit deposit event
		emit AVAXDeposited(contractName, msg.value);
		// Update balances
		avaxBalances[contractName] = avaxBalances[contractName] + msg.value;
	}

	/// @notice Withdraw an amount of AVAX to a network contract
	/// @param amount Amount of AVAX to be withdrawn
	function withdrawAVAX(uint256 amount) external nonReentrant onlyRegisteredNetworkContract {
		// Valid Amount?
		if (amount == 0) {
			revert InvalidAmount();
		}
		// Get the contract name the call is coming from
		string memory contractName = getContractName(msg.sender);
		// Emit the withdraw event for that contract
		emit AVAXWithdrawn(contractName, amount);
		// Verify there are enough funds
		if (avaxBalances[contractName] < amount) {
			revert InsufficientContractBalance();
		}
		// Update balance
		avaxBalances[contractName] = avaxBalances[contractName] - amount;
		IWithdrawer withdrawer = IWithdrawer(msg.sender);
		withdrawer.receiveWithdrawalAVAX{value: amount}();
	}

	/// @notice Transfer AVAX from one contract to another
	/// @dev No funds actually move, just bookkeeping
	/// @param toContractName Name of the contract funds are being transferred to
	/// @param amount How many AVAX to be transferred
	function transferAVAX(string memory toContractName, uint256 amount) external onlyRegisteredNetworkContract {
		// Valid Amount?
		if (amount == 0) {
			revert InvalidAmount();
		}
		// Make sure the contract is valid, will revert if not
		getContractAddress(toContractName);
		string memory fromContractName = getContractName(msg.sender);
		// Emit transfer event
		emit AVAXTransfer(fromContractName, toContractName, amount);
		// Verify there are enough funds
		if (avaxBalances[fromContractName] < amount) {
			revert InsufficientContractBalance();
		}
		// Update balances
		avaxBalances[fromContractName] = avaxBalances[fromContractName] - amount;
		avaxBalances[toContractName] = avaxBalances[toContractName] + amount;
	}

	/// @notice Accept a token deposit and assign its balance to a network contract
	/// @dev (saves a large amount of gas this way through not needing a double token transfer via a network contract first)
	/// @param networkContractName Name of the contract that the token will be assigned to
	/// @param tokenContract The contract of the token being deposited
	/// @param amount How many tokens being deposited
	function depositToken(string memory networkContractName, ERC20 tokenContract, uint256 amount) external guardianOrRegisteredContract {
		// Valid Amount?
		if (amount == 0) {
			revert InvalidAmount();
		}
		// Make sure the network contract is valid (will revert if not)
		getContractAddress(networkContractName);
		// Make sure we accept this token
		if (!allowedTokens[address(tokenContract)]) {
			revert InvalidToken();
		}
		// Get contract key
		bytes32 contractKey = keccak256(abi.encodePacked(networkContractName, address(tokenContract)));
		// Emit token transfer event
		emit TokenDeposited(contractKey, address(tokenContract), amount);
		// Send tokens to this address now, safeTransfer will revert if it fails
		tokenContract.safeTransferFrom(msg.sender, address(this), amount);
		// Update balances
		tokenBalances[contractKey] = tokenBalances[contractKey] + amount;
	}

	/// @notice Withdraw an amount of a ERC20 token to an address
	/// @param withdrawalAddress Address that will receive the token
	/// @param tokenAddress ERC20 token
	/// @param amount Number of tokens to be withdrawn
	function withdrawToken(address withdrawalAddress, ERC20 tokenAddress, uint256 amount) external nonReentrant onlyRegisteredNetworkContract {
		// Valid Amount?
		if (amount == 0) {
			revert InvalidAmount();
		}
		// Get contract key
		bytes32 contractKey = keccak256(abi.encodePacked(getContractName(msg.sender), tokenAddress));
		// Emit token withdrawn event
		emit TokenWithdrawn(contractKey, address(tokenAddress), amount);
		// Verify there are enough funds
		if (tokenBalances[contractKey] < amount) {
			revert InsufficientContractBalance();
		}
		// Update balances
		tokenBalances[contractKey] = tokenBalances[contractKey] - amount;
		// Get the toke ERC20 instance
		ERC20 tokenContract = ERC20(tokenAddress);
		// Withdraw to the withdrawal address, safeTransfer will revert if it fails
		tokenContract.safeTransfer(withdrawalAddress, amount);
	}

	/// @notice Transfer token from one contract to another
	/// @param networkContractName Name of the contract that the token will be transferred to
	/// @param tokenAddress ERC20 token
	/// @param amount Number of tokens to be withdrawn
	function transferToken(string memory networkContractName, ERC20 tokenAddress, uint256 amount) external onlyRegisteredNetworkContract {
		// Valid Amount?
		if (amount == 0) {
			revert InvalidAmount();
		}
		// Make sure the network contract is valid (will revert if not)
		getContractAddress(networkContractName);
		// Get contract keys
		bytes32 contractKeyFrom = keccak256(abi.encodePacked(getContractName(msg.sender), tokenAddress));
		bytes32 contractKeyTo = keccak256(abi.encodePacked(networkContractName, tokenAddress));
		// emit token transfer event
		emit TokenTransfer(contractKeyFrom, contractKeyTo, address(tokenAddress), amount);
		// Verify there are enough funds
		if (tokenBalances[contractKeyFrom] < amount) {
			revert InsufficientContractBalance();
		}
		// Update Balances
		tokenBalances[contractKeyFrom] = tokenBalances[contractKeyFrom] - amount;
		tokenBalances[contractKeyTo] = tokenBalances[contractKeyTo] + amount;
	}

	/// @notice Get the AVAX balance held by a network contract
	/// @param networkContractName Name of the contract who's AVAX balance is being requested
	/// @return The amount in AVAX that the given contract is holding
	function balanceOf(string memory networkContractName) external view returns (uint256) {
		return avaxBalances[networkContractName];
	}

	/// @notice Get the balance of a token held by a network contract
	/// @param networkContractName Name of the contract who's token balance is being requested
	/// @param tokenAddress address of the ERC20 token
	/// @return The amount in given ERC20 token that the given contract is holding
	function balanceOfToken(string memory networkContractName, ERC20 tokenAddress) external view returns (uint256) {
		return tokenBalances[keccak256(abi.encodePacked(networkContractName, tokenAddress))];
	}

	/// @notice Add a token to the protocol's allow list
	/// @param tokenAddress address of a ERC20 token
	function addAllowedToken(address tokenAddress) external onlyGuardian {
		allowedTokens[tokenAddress] = true;
	}

	/// @notice Remove a token from the protocol's allow list
	/// @param tokenAddress address of a ERC20 token
	function removeAllowedToken(address tokenAddress) external onlyGuardian {
		allowedTokens[tokenAddress] = false;
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "../Base.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Storage} from "../Storage.sol";
import {Vault} from "../Vault.sol";

// GGP Governance and Utility Token
// Inflationary with rate determined by DAO

contract TokenGGP is ERC20, Base {
	uint256 private constant INITIAL_SUPPLY = 18_000_000 ether;
	uint256 public constant MAX_SUPPLY = 22_500_000 ether;

	error MaximumTokensReached();

	constructor(Storage storageAddress) ERC20("GoGoPool Protocol", "GGP", 18) Base(storageAddress) {
		// minting to GoGoPool Foundation address
		_mint(address(0xd98C0e8352352b3c486Cc9676F1b593F4cf28102), INITIAL_SUPPLY);
	}

	/// @notice Mint new GGP tokens
	/// @param amount Number of GGP tokens to be minted
	function mint(uint256 amount) external onlySpecificRegisteredContract("RewardsPool", msg.sender) {
		if (totalSupply + amount > MAX_SUPPLY) {
			revert MaximumTokensReached();
		}

		ERC20 ggp = ERC20(address(this));
		Vault vault = Vault(getContractAddress("Vault"));

		_mint(address(this), amount);
		ggp.approve(address(vault), amount);
		vault.depositToken("RewardsPool", ggp, amount);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
// Copied from https://github.com/fei-protocol/ERC4626/blob/main/src/xERC4626.sol
// Rewards logic inspired by xERC20 (https://github.com/ZeframLou/playpen/blob/main/src/xERC20.sol)
pragma solidity 0.8.17;

import "../BaseUpgradeable.sol";
import {ERC20Upgradeable} from "./upgradeable/ERC20Upgradeable.sol";
import {ERC4626Upgradeable} from "./upgradeable/ERC4626Upgradeable.sol";
import {ProtocolDAO} from "../ProtocolDAO.sol";
import {Storage} from "../Storage.sol";

import {IWithdrawer} from "../../interface/IWithdrawer.sol";
import {IWAVAX} from "../../interface/IWAVAX.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/// @dev Local variables and parent contracts must remain in order between contract upgrades
contract TokenggAVAX is Initializable, ERC4626Upgradeable, BaseUpgradeable {
	using SafeTransferLib for ERC20;
	using SafeTransferLib for address;
	using SafeCastLib for *;
	using FixedPointMathLib for uint256;

	error SyncError();
	error ZeroShares();
	error ZeroAssets();
	error InvalidStakingDeposit();

	event NewRewardsCycle(uint256 indexed cycleEnd, uint256 rewardsAmt);
	event WithdrawnForStaking(address indexed caller, uint256 assets);
	event DepositedFromStaking(address indexed caller, uint256 baseAmt, uint256 rewardsAmt);

	/// @notice the effective start of the current cycle
	uint32 public lastSync;

	/// @notice the maximum length of a rewards cycle
	uint32 public rewardsCycleLength;

	/// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
	uint32 public rewardsCycleEnd;

	/// @notice the amount of rewards distributed in a the most recent cycle.
	uint192 public lastRewardsAmt;

	/// @notice the total amount of avax (including avax sent out for staking and all incoming rewards)
	uint256 public totalReleasedAssets;

	/// @notice total amount of avax currently out for staking (not including any rewards)
	uint256 public stakingTotalAssets;

	modifier whenTokenNotPaused(uint256 amt) {
		if (amt > 0 && getBool(keccak256(abi.encodePacked("contract.paused", "TokenggAVAX")))) {
			revert ContractPaused();
		}
		_;
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		// The constructor is executed only when creating implementation contract
		// so prevent it's reinitialization
		_disableInitializers();
	}

	function initialize(Storage storageAddress, ERC20 asset, uint256 initialDeposit) public initializer {
		__ERC4626Upgradeable_init(asset, "GoGoPool Liquid Staking Token", "ggAVAX");
		__BaseUpgradeable_init(storageAddress);

		version = 1;

		// sacrifice initial seed of shares to prevent front-running early deposits
		if (initialDeposit > 0) {
			deposit(initialDeposit, address(this));
		}

		rewardsCycleLength = 14 days;
		// Ensure it will be evenly divisible by `rewardsCycleLength`.
		rewardsCycleEnd = (block.timestamp.safeCastTo32() / rewardsCycleLength) * rewardsCycleLength;
	}

	/// @notice only accept AVAX via fallback from the WAVAX contract
	receive() external payable {
		require(msg.sender == address(asset));
	}

	/// @notice Distributes rewards to TokenggAVAX holders. Public, anyone can call.
	/// 				All surplus `asset` balance of the contract over the internal balance becomes queued for the next cycle.
	function syncRewards() public {
		uint32 timestamp = block.timestamp.safeCastTo32();

		if (timestamp < rewardsCycleEnd) {
			revert SyncError();
		}

		uint192 lastRewardsAmt_ = lastRewardsAmt;
		uint256 totalReleasedAssets_ = totalReleasedAssets;
		uint256 stakingTotalAssets_ = stakingTotalAssets;

		uint256 nextRewardsAmt = (asset.balanceOf(address(this)) + stakingTotalAssets_) - totalReleasedAssets_ - lastRewardsAmt_;

		// Ensure nextRewardsCycleEnd will be evenly divisible by `rewardsCycleLength`.
		uint32 nextRewardsCycleEnd = ((timestamp + rewardsCycleLength) / rewardsCycleLength) * rewardsCycleLength;

		lastRewardsAmt = nextRewardsAmt.safeCastTo192();
		lastSync = timestamp;
		rewardsCycleEnd = nextRewardsCycleEnd;
		totalReleasedAssets = totalReleasedAssets_ + lastRewardsAmt_;
		emit NewRewardsCycle(nextRewardsCycleEnd, nextRewardsAmt);
	}

	/// @notice Compute the amount of tokens available to share holders.
	///         Increases linearly during a reward distribution period from the sync call, not the cycle start.
	/// @return The amount of ggAVAX tokens available
	function totalAssets() public view override returns (uint256) {
		// cache global vars
		uint256 totalReleasedAssets_ = totalReleasedAssets;
		uint192 lastRewardsAmt_ = lastRewardsAmt;
		uint32 rewardsCycleEnd_ = rewardsCycleEnd;
		uint32 lastSync_ = lastSync;

		if (block.timestamp >= rewardsCycleEnd_) {
			// no rewards or rewards are fully unlocked
			// entire reward amount is available
			return totalReleasedAssets_ + lastRewardsAmt_;
		}

		// rewards are not fully unlocked
		// return unlocked rewards and stored total
		uint256 unlockedRewards = (lastRewardsAmt_ * (block.timestamp - lastSync_)) / (rewardsCycleEnd_ - lastSync_);
		return totalReleasedAssets_ + unlockedRewards;
	}

	/// @notice Returns the AVAX amount that is available for staking on minipools
	/// @return uint256 AVAX available for staking
	function amountAvailableForStaking() public view returns (uint256) {
		ProtocolDAO protocolDAO = ProtocolDAO(getContractAddress("ProtocolDAO"));
		uint256 targetCollateralRate = protocolDAO.getTargetGGAVAXReserveRate();

		uint256 totalAssets_ = totalAssets();

		uint256 reservedAssets = totalAssets_.mulDivDown(targetCollateralRate, 1 ether);

		if (reservedAssets + stakingTotalAssets > totalAssets_) {
			return 0;
		}
		return totalAssets_ - reservedAssets - stakingTotalAssets;
	}

	/// @notice Accepts AVAX deposit from a minipool. Expects the base amount and rewards earned from staking
	/// @param baseAmt The amount of liquid staker AVAX used to create a minipool
	/// @param rewardAmt The rewards amount (in AVAX) earned from staking
	function depositFromStaking(uint256 baseAmt, uint256 rewardAmt) public payable onlySpecificRegisteredContract("MinipoolManager", msg.sender) {
		uint256 totalAmt = msg.value;
		if (totalAmt != (baseAmt + rewardAmt) || baseAmt > stakingTotalAssets) {
			revert InvalidStakingDeposit();
		}

		emit DepositedFromStaking(msg.sender, baseAmt, rewardAmt);
		stakingTotalAssets -= baseAmt;
		IWAVAX(address(asset)).deposit{value: totalAmt}();
	}

	/// @notice Allows the MinipoolManager contract to withdraw liquid staker funds to create a minipool
	/// @param assets The amount of AVAX to withdraw
	function withdrawForStaking(uint256 assets) public onlySpecificRegisteredContract("MinipoolManager", msg.sender) {
		emit WithdrawnForStaking(msg.sender, assets);

		stakingTotalAssets += assets;
		IWAVAX(address(asset)).withdraw(assets);
		IWithdrawer withdrawer = IWithdrawer(msg.sender);
		withdrawer.receiveWithdrawalAVAX{value: assets}();
	}

	/// @notice Allows users to deposit AVAX and receive ggAVAX
	/// @return shares The amount of ggAVAX minted
	function depositAVAX() public payable returns (uint256 shares) {
		uint256 assets = msg.value;
		// Check for rounding error since we round down in previewDeposit.
		if ((shares = previewDeposit(assets)) == 0) {
			revert ZeroShares();
		}

		emit Deposit(msg.sender, msg.sender, assets, shares);

		IWAVAX(address(asset)).deposit{value: assets}();
		_mint(msg.sender, shares);
		afterDeposit(assets, shares);
	}

	/// @notice Allows users to specify an amount of AVAX to withdraw from their ggAVAX supply
	/// @param assets Amount of AVAX to be withdrawn
	/// @return shares Amount of ggAVAX burned
	function withdrawAVAX(uint256 assets) public returns (uint256 shares) {
		shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.
		beforeWithdraw(assets, shares);
		_burn(msg.sender, shares);

		emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);

		IWAVAX(address(asset)).withdraw(assets);
		msg.sender.safeTransferETH(assets);
	}

	/// @notice Allows users to specify shares of ggAVAX to redeem for AVAX
	/// @param shares Amount of ggAVAX to burn
	/// @return assets Amount of AVAX withdrawn
	function redeemAVAX(uint256 shares) public returns (uint256 assets) {
		// Check for rounding error since we round down in previewRedeem.
		if ((assets = previewRedeem(shares)) == 0) {
			revert ZeroAssets();
		}
		beforeWithdraw(assets, shares);
		_burn(msg.sender, shares);

		emit Withdraw(msg.sender, msg.sender, msg.sender, assets, shares);

		IWAVAX(address(asset)).withdraw(assets);
		msg.sender.safeTransferETH(assets);
	}

	/// @notice Max assets an owner can deposit
	/// @param _owner User wallet address
	/// @return The max amount of ggAVAX an owner can deposit
	function maxDeposit(address _owner) public view override returns (uint256) {
		if (getBool(keccak256(abi.encodePacked("contract.paused", "TokenggAVAX")))) {
			return 0;
		}
		return super.maxDeposit(_owner);
	}

	/// @notice Max shares owner can mint
	/// @param _owner User wallet address
	/// @return The max amount of ggAVAX an owner can mint
	function maxMint(address _owner) public view override returns (uint256) {
		if (getBool(keccak256(abi.encodePacked("contract.paused", "TokenggAVAX")))) {
			return 0;
		}
		return super.maxMint(_owner);
	}

	/// @notice Max assets an owner can withdraw with consideration to liquidity in this contract
	/// @param _owner User wallet address
	/// @return The max amount of ggAVAX an owner can withdraw
	function maxWithdraw(address _owner) public view override returns (uint256) {
		uint256 assets = convertToAssets(balanceOf[_owner]);
		uint256 avail = totalAssets() - stakingTotalAssets;
		return assets > avail ? avail : assets;
	}

	/// @notice Max shares owner can withdraw with consideration to liquidity in this contract
	/// @param _owner User wallet address
	/// @return The max amount of ggAVAX an owner can redeem
	function maxRedeem(address _owner) public view override returns (uint256) {
		uint256 shares = balanceOf[_owner];
		uint256 avail = convertToShares(totalAssets() - stakingTotalAssets);
		return shares > avail ? avail : shares;
	}

	/// @notice Preview shares minted for AVAX deposit
	/// @param assets Amount of AVAX to deposit
	/// @return uint256 Amount of ggAVAX that would be minted
	function previewDeposit(uint256 assets) public view override whenTokenNotPaused(assets) returns (uint256) {
		return super.previewDeposit(assets);
	}

	/// @notice Preview assets required for mint of shares
	/// @param shares Amount of ggAVAX to mint
	/// @return uint256 Amount of AVAX required
	function previewMint(uint256 shares) public view override whenTokenNotPaused(shares) returns (uint256) {
		return super.previewMint(shares);
	}

	/// @notice Function prior to a withdraw
	/// @param amount Amount of AVAX
	function beforeWithdraw(uint256 amount, uint256 /* shares */) internal override {
		totalReleasedAssets -= amount;
	}

	/// @notice Function after a deposit
	/// @param amount Amount of AVAX
	function afterDeposit(uint256 amount, uint256 /* shares */) internal override {
		totalReleasedAssets += amount;
	}

	/// @notice Override of ERC20Upgradeable to set the contract version for EIP-2612
	/// @return hash of this contracts version
	function versionHash() internal view override returns (bytes32) {
		return keccak256(abi.encodePacked(version));
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20Upgradeable is Initializable {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 amount);

	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

	string public name;

	string public symbol;

	uint8 public decimals;

	/*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

	uint256 public totalSupply;

	mapping(address => uint256) public balanceOf;

	mapping(address => mapping(address => uint256)) public allowance;

	/*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

	uint256 internal INITIAL_CHAIN_ID;

	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

	mapping(address => uint256) public nonces;

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	function __ERC20Upgradeable_init(string memory _name, string memory _symbol, uint8 _decimals) internal onlyInitializing {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;

		INITIAL_CHAIN_ID = block.chainid;
		INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
	}

	/*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

	function approve(address spender, uint256 amount) public virtual returns (bool) {
		allowance[msg.sender][spender] = amount;

		emit Approval(msg.sender, spender, amount);

		return true;
	}

	function transfer(address to, uint256 amount) public virtual returns (bool) {
		balanceOf[msg.sender] -= amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(msg.sender, to, amount);

		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
		uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

		if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

		balanceOf[from] -= amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(from, to, amount);

		return true;
	}

	/*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
		require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

		// Unchecked because the only math done is incrementing
		// the owner's nonce which cannot realistically overflow.
		unchecked {
			address recoveredAddress = ecrecover(
				keccak256(
					abi.encodePacked(
						"\x19\x01",
						DOMAIN_SEPARATOR(),
						keccak256(
							abi.encode(
								keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
								owner,
								spender,
								value,
								nonces[owner]++,
								deadline
							)
						)
					)
				),
				v,
				r,
				s
			);

			require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

			allowance[recoveredAddress][spender] = value;
		}

		emit Approval(owner, spender, value);
	}

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
	}

	function computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
					keccak256(bytes(name)),
					versionHash(),
					block.chainid,
					address(this)
				)
			);
	}

	function versionHash() internal view virtual returns (bytes32);

	/*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(address to, uint256 amount) internal virtual {
		totalSupply += amount;

		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value.
		unchecked {
			balanceOf[to] += amount;
		}

		emit Transfer(address(0), to, amount);
	}

	function _burn(address from, uint256 amount) internal virtual {
		balanceOf[from] -= amount;

		// Cannot underflow because a user's balance
		// will never be larger than the total supply.
		unchecked {
			totalSupply -= amount;
		}

		emit Transfer(from, address(0), amount);
	}

	/// @dev This empty reserved space is put in place to allow future versions to add new
	/// variables without shifting down storage in the inheritance chain.
	uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {FixedPointMathLib} from "@rari-capital/solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/*//////////////////////////////////////////////////////////////
		EVENTS
	//////////////////////////////////////////////////////////////*/

	event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

	event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

	/*//////////////////////////////////////////////////////////////
		IMMUTABLES
		//////////////////////////////////////////////////////////////*/

	ERC20 public asset;

	function __ERC4626Upgradeable_init(ERC20 _asset, string memory _name, string memory _symbol) internal onlyInitializing {
		__ERC20Upgradeable_init(_name, _symbol, _asset.decimals());
		asset = _asset;
	}

	/*//////////////////////////////////////////////////////////////
			DEPOSIT/WITHDRAWAL LOGIC
		//////////////////////////////////////////////////////////////*/

	function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
		// Check for rounding error since we round down in previewDeposit.
		require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

		// Need to transfer before minting or ERC777s could reenter.
		asset.safeTransferFrom(msg.sender, address(this), assets);

		_mint(receiver, shares);

		emit Deposit(msg.sender, receiver, assets, shares);

		afterDeposit(assets, shares);
	}

	function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
		assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

		// Need to transfer before minting or ERC777s could reenter.
		asset.safeTransferFrom(msg.sender, address(this), assets);

		_mint(receiver, shares);

		emit Deposit(msg.sender, receiver, assets, shares);

		afterDeposit(assets, shares);
	}

	function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
		shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

		if (msg.sender != owner) {
			uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

			if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
		}

		beforeWithdraw(assets, shares);

		_burn(owner, shares);

		emit Withdraw(msg.sender, receiver, owner, assets, shares);

		asset.safeTransfer(receiver, assets);
	}

	function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
		if (msg.sender != owner) {
			uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

			if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
		}

		// Check for rounding error since we round down in previewRedeem.
		require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

		beforeWithdraw(assets, shares);

		_burn(owner, shares);

		emit Withdraw(msg.sender, receiver, owner, assets, shares);

		asset.safeTransfer(receiver, assets);
	}

	/*//////////////////////////////////////////////////////////////
		ACCOUNTING LOGIC
	//////////////////////////////////////////////////////////////*/

	function totalAssets() public view virtual returns (uint256);

	function convertToShares(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 shares) public view virtual returns (uint256) {
		uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
	}

	function previewDeposit(uint256 assets) public view virtual returns (uint256) {
		return convertToShares(assets);
	}

	function previewMint(uint256 shares) public view virtual returns (uint256) {
		uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
	}

	function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
	}

	function previewRedeem(uint256 shares) public view virtual returns (uint256) {
		return convertToAssets(shares);
	}

	/*//////////////////////////////////////////////////////////////
		DEPOSIT/WITHDRAWAL LIMIT LOGIC
	//////////////////////////////////////////////////////////////*/

	function maxDeposit(address) public view virtual returns (uint256) {
		return type(uint256).max;
	}

	function maxMint(address) public view virtual returns (uint256) {
		return type(uint256).max;
	}

	function maxWithdraw(address owner) public view virtual returns (uint256) {
		return convertToAssets(balanceOf[owner]);
	}

	function maxRedeem(address owner) public view virtual returns (uint256) {
		return balanceOf[owner];
	}

	/*//////////////////////////////////////////////////////////////
		INTERNAL HOOKS LOGIC
	//////////////////////////////////////////////////////////////*/

	function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

	function afterDeposit(uint256 assets, uint256 shares) internal virtual {}

	/// @dev This empty reserved space is put in place to allow future versions to add new
	/// variables without shifting down storage in the inheritance chain.
	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

// [GGP] use the real WAVAX instead of this when deploying to prod

contract WAVAX is ERC20("Wrapped AVAX", "AVAX", 18) {
	using SafeTransferLib for address;

	event Deposit(address indexed from, uint256 amount);

	event Withdrawal(address indexed to, uint256 amount);

	function deposit() public payable virtual {
		_mint(msg.sender, msg.value);

		emit Deposit(msg.sender, msg.value);
	}

	function withdraw(uint256 amount) public virtual {
		_burn(msg.sender, amount);

		emit Withdrawal(msg.sender, amount);

		msg.sender.safeTransferETH(amount);
	}

	receive() external payable virtual {
		deposit();
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IWAVAX {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	function balanceOf(address owner) external view returns (uint256);

	function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @dev Must implement this interface to receive funds from Vault.sol
interface IWithdrawer {
	function receiveWithdrawalAVAX() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }
    
    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}