// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IRoundtableDAO} from '../../../interfaces/IRoundtableDAO.sol';

import {ReentrancyGuard} from '../../../utils/ReentrancyGuard.sol';

/// @notice Allows members to stake group tokens and assign voting power to others
/// @author Modified from Kali DAO Extension template
contract Delegator is ReentrancyGuard {
	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event ExtensionSet(address indexed dao, address[] members);
	event ExtensionCalled(
		address indexed dao,
		address indexed from,
		address indexed to,
		uint256 amount,
		DelegationType typeOfCall
	);
	event DelegateChanged(
		address indexed delegator,
		address indexed fromDelegate,
		address indexed toDelegate
	);
	event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

	/// -----------------------------------------------------------------------
	/// Errors
	/// -----------------------------------------------------------------------

	error SignatureExpired();
	error NullAddress();
	error InvalidNonce();
	error MembersMissing();
	error Forbidden();
	error NotDetermined();
	error Uint32max();
	error Uint96max();

	/// -----------------------------------------------------------------------
	/// EIP-712 Storage
	/// -----------------------------------------------------------------------

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
	}

	function _computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					),
					keccak256(bytes('Delegator')),
					keccak256('1'),
					block.chainid,
					address(this)
				)
			);
	}

	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

	uint256 internal INITIAL_CHAIN_ID;

	mapping(address => uint256) public nonces;

	/// -----------------------------------------------------------------------
	/// Delegator Storage
	/// -----------------------------------------------------------------------

	enum DelegationType {
		GET_VOTES,
		SET_VOTES
	}

	uint256 constant MEMBERSHIP = 0;
	uint256 constant TOKEN = 1;

	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256(
			'Delegation(address dao,address delegator,address delegatee,uint256 nonce,uint256 deadline)'
		);

	mapping(address => mapping(address => address)) internal _delegates;
	mapping(address => mapping(address => mapping(uint256 => Checkpoint))) public checkpoints;
	mapping(address => mapping(address => uint256)) public numCheckpoints;
	mapping(address => mapping(address => uint256)) public balanceTracker;

	struct Checkpoint {
		uint32 fromTimestamp;
		uint96 votes;
	}

	/// -----------------------------------------------------------------------
	/// Constructor
	/// -----------------------------------------------------------------------

	constructor() {
		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
	}

	/// -----------------------------------------------------------------------
	/// Delegation Settings
	/// -----------------------------------------------------------------------

	function setExtension(bytes calldata extensionData) external {
		(address dao, address[] memory members) = abi.decode(extensionData, (address, address[]));

		if (msg.sender != dao) revert Forbidden();

		address prevAddr;
		uint256 len = members.length;

		// If not all members are included in the setup (reverts in cases where a new member is added after delegation is proposed)
		if (IRoundtableDAO(dao).memberCount() != len) revert MembersMissing();

		for (uint256 i; i < len; ) {
			// Ensures no duplicates, when combined with the check below it ensures all members are included in the setup
			if (prevAddr >= members[i]) revert MembersMissing();

			// Can only delegate votes to existing members
			if (IRoundtableDAO(dao).balanceOf(members[i], MEMBERSHIP) == 0) revert Forbidden();

			uint256 tmpNumCheckpoints = numCheckpoints[dao][members[i]];
			uint256 tmpvotes = tmpNumCheckpoints != 0
				? checkpoints[dao][members[i]][tmpNumCheckpoints - 1].votes
				: 0;

			// If the extension is already set, then calling it again will 'unset', returning all voting balances to 0.
			// This is required because while delegation is disabled, treasury share will not be tracked on this extension, meaning
			// that when it is reenabled, the voting balances here will not match. Instead they are reset from 0.
			if (tmpvotes == 0) {
				uint256 tokenBalance = IRoundtableDAO(dao).balanceOf(members[i], TOKEN);

				// Set voting balances to equal the token balance of each member in the dao
				_writeCheckpoint(dao, members[i], tmpNumCheckpoints, 0, tokenBalance);
			} else {
				// Set voting balances to 0
				_writeCheckpoint(dao, members[i], tmpNumCheckpoints, tmpvotes, 0);
			}

			unchecked {
				++i;
			}
		}

		emit ExtensionSet(address(dao), members);
	}

	/// -----------------------------------------------------------------------
	/// Delegator Functions
	/// -----------------------------------------------------------------------

	function callExtension(
		address sender,
		uint256 votesIn,
		bytes calldata extensionData
	) external nonReentrant returns (bool mint, uint256 amount) {
		(address dao, address from, address to, uint32 timestamp, DelegationType typeOfCall) = abi
			.decode(extensionData, (address, address, address, uint32, DelegationType));

		// Get votes - this format allows the dao multisig to get vote counts using the standard extension template
		if (typeOfCall == DelegationType.GET_VOTES) {
			mint = false;
			amount = getPriorVotes(dao, from, timestamp);
		}

		// Set votes - covers minting or burning of tokens by the dao
		if (typeOfCall == DelegationType.SET_VOTES) {
			// Only the dao can call this function
			if (msg.sender != dao) revert Forbidden();

			// Can only delegate to existing members [[ TODO consider making this optional depending on PAUSED]]
			if (IRoundtableDAO(dao).balanceOf(to, MEMBERSHIP) == 0) revert Forbidden();

			// We can not let the amount of votes be an input since the dao could assign votes which don't align with balances
			uint256 voteAmount;
			address member;

			if (from == address(0)) member = to;
			else member = from;

			uint256 currentBal = balanceTracker[dao][member];
			uint256 newBal = IRoundtableDAO(dao).balanceOf(member, TOKEN);

			// Ensures we don't get negative values for the difference
			if (newBal > currentBal) voteAmount = newBal - currentBal;
			else voteAmount = currentBal - newBal;

			_moveDelegates(dao, delegates(dao, from), to, voteAmount);
		}

		emit ExtensionCalled(dao, from, to, amount, typeOfCall);
	}

	function delegates(address dao, address delegator) public view virtual returns (address) {
		address current = _delegates[dao][delegator];

		return current == address(0) ? delegator : current;
	}

	function getCurrentVotes(address dao, address account) public view virtual returns (uint256) {
		// This is safe from underflow because decrement only occurs if `nCheckpoints` is positive
		unchecked {
			uint256 nCheckpoints = numCheckpoints[dao][account];

			return nCheckpoints != 0 ? checkpoints[dao][account][nCheckpoints - 1].votes : 0;
		}
	}

	function delegate(address dao, address delegatee) public payable virtual {
		_delegate(dao, msg.sender, delegatee);
	}

	function delegateBySig(
		address dao,
		address delegator,
		address delegatee,
		uint256 nonce,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public payable virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		// Can only delegate votes to existing members
		if (IRoundtableDAO(dao).balanceOf(delegatee, MEMBERSHIP) == 0) revert Forbidden();

		bytes32 structHash = keccak256(
			abi.encode(DELEGATION_TYPEHASH, dao, delegator, delegatee, nonce, deadline)
		);

		bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

		address signatory = ecrecover(digest, v, r, s);

		if (signatory != delegator) revert NullAddress();

		// Cannot realistically overflow on human timescales
		unchecked {
			if (nonce != nonces[signatory]++) revert InvalidNonce();
		}

		_delegate(dao, signatory, delegatee);
	}

	function getPriorVotes(
		address dao,
		address account,
		uint256 timestamp
	) public view virtual returns (uint96) {
		if (block.timestamp <= timestamp) revert NotDetermined();

		uint256 nCheckpoints = numCheckpoints[dao][account];

		if (nCheckpoints == 0) return 0;

		// this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
		unchecked {
			if (checkpoints[dao][account][nCheckpoints - 1].fromTimestamp <= timestamp)
				return checkpoints[dao][account][nCheckpoints - 1].votes;

			if (checkpoints[dao][account][0].fromTimestamp > timestamp) return 0;

			uint256 lower;

			// This is safe from underflow because decrement only occurs if `nCheckpoints` is positive
			uint256 upper = nCheckpoints - 1;

			while (upper > lower) {
				// this is safe from underflow because `upper` ceiling is provided
				uint256 center = upper - (upper - lower) / 2;

				Checkpoint memory cp = checkpoints[dao][account][center];

				if (cp.fromTimestamp == timestamp) {
					return cp.votes;
				} else if (cp.fromTimestamp < timestamp) {
					lower = center;
				} else {
					upper = center - 1;
				}
			}

			return checkpoints[dao][account][lower].votes;
		}
	}

	function _delegate(
		address dao,
		address delegator,
		address delegatee
	) internal virtual {
		address currentDelegate = delegates(dao, delegator);

		_delegates[dao][delegator] = delegatee;

		_moveDelegates(
			dao,
			currentDelegate,
			delegatee,
			IRoundtableDAO(dao).balanceOf(delegator, TOKEN)
		);

		emit DelegateChanged(delegator, currentDelegate, delegatee);
	}

	function _moveDelegates(
		address dao,
		address srcRep,
		address dstRep,
		uint256 amount
	) internal virtual {
		if (srcRep != dstRep && amount != 0)
			if (srcRep != address(0)) {
				uint256 srcRepNum = numCheckpoints[dao][srcRep];

				uint256 srcRepOld = srcRepNum != 0 ? checkpoints[dao][srcRep][srcRepNum - 1].votes : 0;

				uint256 srcRepNew = srcRepOld - amount;

				_writeCheckpoint(dao, srcRep, srcRepNum, srcRepOld, srcRepNew);
			}

		if (dstRep != address(0)) {
			uint256 dstRepNum = numCheckpoints[dao][dstRep];

			uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dao][dstRep][dstRepNum - 1].votes : 0;

			uint256 dstRepNew = dstRepOld + amount;

			_writeCheckpoint(dao, dstRep, dstRepNum, dstRepOld, dstRepNew);
		}
	}

	function _writeCheckpoint(
		address dao,
		address delegatee,
		uint256 nCheckpoints,
		uint256 oldVotes,
		uint256 newVotes
	) internal virtual {
		unchecked {
			// This is safe from underflow because decrement only occurs if `nCheckpoints` is positive
			if (
				nCheckpoints != 0 &&
				checkpoints[dao][delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp
			) {
				checkpoints[dao][delegatee][nCheckpoints - 1].votes = _safeCastTo96(newVotes);
			} else {
				checkpoints[dao][delegatee][nCheckpoints] = Checkpoint(
					_safeCastTo32(block.timestamp),
					_safeCastTo96(newVotes)
				);

				// Cannot realistically overflow on human timescales
				numCheckpoints[dao][delegatee] = nCheckpoints + 1;
			}
			// Track the current balance of the member - this is used later when updating the voting balances after minting new tokens
			balanceTracker[dao][delegatee] = IRoundtableDAO(dao).balanceOf(delegatee, TOKEN);
		}

		emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
	}

	/*///////////////////////////////////////////////////////////////
                            SAFECAST LOGIC
    //////////////////////////////////////////////////////////////*/

	function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
		if (x > type(uint32).max) revert Uint32max();

		return uint32(x);
	}

	function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
		if (x > type(uint96).max) revert Uint96max();

		return uint96(x);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Roundtable DAO share manager interface
interface IRoundtableDAO {
	function balanceOf(address to, uint256 tokenId) external payable returns (uint256);

	function proposalCount() external payable returns (uint256);

	function memberCount() external payable returns (uint256);

	function mintShares(
		address to,
		uint256 id,
		uint256 amount
	) external payable;

	function burnShares(
		address from,
		uint256 id,
		uint256 amount
	) external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/utils/ReentrancyGuard.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract ReentrancyGuard {
	error Reentrancy();

	uint256 private locked = 1;

	modifier nonReentrant() {
		if (locked != 1) revert Reentrancy();

		locked = 2;
		_;
		locked = 1;
	}
}