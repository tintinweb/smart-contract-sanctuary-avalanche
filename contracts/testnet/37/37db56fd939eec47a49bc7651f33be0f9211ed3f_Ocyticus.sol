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

import {Base} from "./Base.sol";
import {Storage} from "./Storage.sol";
import {Vault} from "./Vault.sol";
import {TokenGGP} from "./tokens/TokenGGP.sol";

/*
	Data Storage Schema
	multisig.count = Starts at 0 and counts up by 1 after an addr is added.

	multisig.index<address> = <index> + 1 of multisigAddress
	multisig.item<index>.address = C-chain address used as primary key
	multisig.item<index>.enabled = bool
*/

/// @title Multisig address creation and management for the protocol
contract MultisigManager is Base {
	uint256 public constant MULTISIG_LIMIT = 10;

	error MultisigAlreadyRegistered();
	error MultisigLimitReached();
	error MultisigMustBeEnabled();
	error MultisigNotFound();
	error NoEnabledMultisigFound();

	event DisabledMultisig(address indexed multisig, address actor);
	event EnabledMultisig(address indexed multisig, address actor);
	event GGPClaimed(address indexed multisig, uint256 amount);
	event RegisteredMultisig(address indexed multisig, address actor);

	/// @notice Verifies the multisig trying is enabled
	modifier onlyEnabledMultisig() {
		int256 multisigIndex = getIndexOf(msg.sender);

		if (multisigIndex == -1) {
			revert MultisigNotFound();
		}

		(, bool isEnabled) = getMultisig(uint256(multisigIndex));

		if (!isEnabled) {
			revert MultisigMustBeEnabled();
		}
		_;
	}

	constructor(Storage storageAddress) Base(storageAddress) {
		version = 1;
	}

	/// @notice Register a multisig. Defaults to disabled when first registered.
	/// @param addr Address of the multisig that is being registered
	function registerMultisig(address addr) external onlyGuardian {
		int256 multisigIndex = getIndexOf(addr);
		if (multisigIndex != -1) {
			revert MultisigAlreadyRegistered();
		}
		uint256 index = getUint(keccak256("multisig.count"));
		if (index >= MULTISIG_LIMIT) {
			revert MultisigLimitReached();
		}

		setAddress(keccak256(abi.encodePacked("multisig.item", index, ".address")), addr);

		// The index is stored 1 greater than the actual value. The 1 is subtracted in getIndexOf().
		setUint(keccak256(abi.encodePacked("multisig.index", addr)), index + 1);
		addUint(keccak256("multisig.count"), 1);
		emit RegisteredMultisig(addr, msg.sender);
	}

	/// @notice Enabling a registered multisig
	/// @param addr Address of the multisig that is being enabled
	function enableMultisig(address addr) external onlyGuardian {
		int256 multisigIndex = getIndexOf(addr);
		if (multisigIndex == -1) {
			revert MultisigNotFound();
		}

		setBool(keccak256(abi.encodePacked("multisig.item", multisigIndex, ".enabled")), true);
		emit EnabledMultisig(addr, msg.sender);
	}

	/// @notice Disabling a registered multisig
	/// @param addr Address of the multisig that is being disabled
	/// @dev this will prevent the multisig from completing validations. The minipool will need to be manually reassigned to a new multisig
	function disableMultisig(address addr) external guardianOrSpecificRegisteredContract("Ocyticus", msg.sender) {
		int256 multisigIndex = getIndexOf(addr);
		if (multisigIndex == -1) {
			revert MultisigNotFound();
		}

		setBool(keccak256(abi.encodePacked("multisig.item", multisigIndex, ".enabled")), false);
		emit DisabledMultisig(addr, msg.sender);
	}

	/// @notice Gets the next registered and enabled Multisig, revert if none found
	/// @return Address of the next active multisig
	/// @dev There will never be more than 10 total multisigs. If we grow beyond that we will redesign this contract.
	function requireNextActiveMultisig() external view returns (address) {
		uint256 total = getUint(keccak256("multisig.count"));
		address addr;
		bool enabled;
		for (uint256 i = 0; i < total; i++) {
			(addr, enabled) = getMultisig(i);
			if (enabled) {
				return addr;
			}
		}
		revert NoEnabledMultisigFound();
	}

	/// @notice The index of a multisig. Returns -1 if the multisig is not found
	/// @param addr Address of the multisig that is being searched for
	/// @return The index for the given multisig
	function getIndexOf(address addr) public view returns (int256) {
		return int256(getUint(keccak256(abi.encodePacked("multisig.index", addr)))) - 1;
	}

	/// @notice Get the total count of the multisigs in the protocol
	/// @return Count of all multisigs
	function getCount() public view returns (uint256) {
		return getUint(keccak256("multisig.count"));
	}

	/// @notice Gets the multisig information using the multisig's index
	/// @param index Index of the multisig
	/// @return addr and enabled. The address and the enabled status of the multisig
	function getMultisig(uint256 index) public view returns (address addr, bool enabled) {
		addr = getAddress(keccak256(abi.encodePacked("multisig.item", index, ".address")));
		enabled = (addr != address(0)) && getBool(keccak256(abi.encodePacked("multisig.item", index, ".enabled")));
	}

	/// @notice Allows an enabled multisig to withdraw the unclaimed GGP rewards
	function withdrawUnclaimedGGP() external onlyEnabledMultisig {
		Vault vault = Vault(getContractAddress("Vault"));
		TokenGGP ggp = TokenGGP(getContractAddress("TokenGGP"));
		uint256 totalGGP = vault.balanceOfToken("MultisigManager", ggp);

		emit GGPClaimed(msg.sender, totalGGP);

		vault.withdrawToken(msg.sender, ggp, totalGGP);
	}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {Base} from "./Base.sol";
import {MultisigManager} from "./MultisigManager.sol";
import {ProtocolDAO} from "./ProtocolDAO.sol";
import {Storage} from "./Storage.sol";

/// @title Methods to pause the protocol
contract Ocyticus is Base {
	error NotAllowed();

	mapping(address => bool) public defenders;

	modifier onlyDefender() {
		if (!defenders[msg.sender]) {
			revert NotAllowed();
		}
		_;
	}

	constructor(Storage storageAddress) Base(storageAddress) {
		defenders[msg.sender] = true;
	}

	/// @notice Add an address to the defender list
	/// @param defender Address to add
	function addDefender(address defender) external onlyGuardian {
		defenders[defender] = true;
	}

	/// @notice Remove an address from the defender list
	/// @param defender address to remove
	function removeDefender(address defender) external onlyGuardian {
		delete defenders[defender];
	}

	/// @notice Restrict actions in important contracts
	function pauseEverything() external onlyDefender {
		ProtocolDAO dao = ProtocolDAO(getContractAddress("ProtocolDAO"));
		dao.pauseContract("MinipoolManager");
		dao.pauseContract("RewardsPool");
		dao.pauseContract("Staking");
		dao.pauseContract("TokenggAVAX");
		disableAllMultisigs();
	}

	/// @notice Reestablish all contract's abilities
	/// @dev Multisigs will need to be enabled separately, we don't know which ones to enable
	function resumeEverything() external onlyDefender {
		ProtocolDAO dao = ProtocolDAO(getContractAddress("ProtocolDAO"));
		dao.resumeContract("MinipoolManager");
		dao.resumeContract("RewardsPool");
		dao.resumeContract("Staking");
		dao.resumeContract("TokenggAVAX");
	}

	/// @notice Disable every multisig in the protocol
	function disableAllMultisigs() public onlyDefender {
		MultisigManager mm = MultisigManager(getContractAddress("MultisigManager"));
		uint256 count = mm.getCount();

		address addr;
		bool enabled;
		for (uint256 i = 0; i < count; i++) {
			(addr, enabled) = mm.getMultisig(i);
			if (enabled) {
				mm.disableMultisig(addr);
			}
		}
	}
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
		_mint(msg.sender, INITIAL_SUPPLY);
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

/// @dev Must implement this interface to receive funds from Vault.sol
interface IWithdrawer {
	function receiveWithdrawalAVAX() external payable;
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