// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {TableGovernance} from './TableGovernance.sol';

import {Multicall} from '../utils/Multicall.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';
import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroupTypes} from '../interfaces/IForumGroupTypes.sol';
import {IForumGroupExtension} from '../interfaces/IForumGroupExtension.sol';
import {IPfpStaker} from '../interfaces/IPfpStaker.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';
import {IExecutionManager} from '../interfaces/IExecutionManager.sol';

/// @notice Forum investment group wallet
/// @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)

//*****
// TODO using pfp staker as exe manager for tests
//*****

contract ForumGroup is
	IForumGroupTypes,
	TableGovernance,
	ReentrancyGuard,
	Multicall,
	NFTreceiver,
	IERC1271
{
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event NewProposal(
		address indexed proposer,
		uint256 indexed proposal,
		ProposalType indexed proposalType,
		address[] accounts,
		uint256[] amounts,
		bytes[] payloads
	);

	event ProposalSponsored(address indexed sponsor, uint256 indexed proposal);

	event VoteCast(address indexed voter, uint256 indexed proposal);

	event ProposalProcessed(
		ProposalType indexed proposalType,
		uint256 indexed proposal,
		bool indexed didProposalPass
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Initialized();

	error MemberLimitExceeded();

	error PeriodBounds();

	error SupermajorityBounds();

	error TypeBounds();

	error NoArrayParity();

	error Sponsored();

	error NotMember();

	error NotCurrentProposal();

	error AlreadyVoted();

	error NotVoteable();

	error VotingNotEnded();

	error NotExtension();

	error PFPFailed();

	error SignatureError();

	error CallError();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	address private pfpExtension;

	uint256 public memberCount;
	uint256 public proposalCount;
	uint256 public currentActiveProposalCount;
	uint32 public votingPeriod;
	uint32 public gracePeriod;
	uint32 public supermajority; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant VOTE_HASH = keccak256('SignVote(address signer,uint256 proposal)');

	/**
	 * 'contractSignatureAllowance' provides the contract with the ability to 'sign' as an EOA would
	 * 	It enables signature based transactions on marketplaces accommodating the EIP-1271 standard.
	 *  Address is the account which makes the call to check the verified signature (ie. the martketplace).
	 * 	Bytes32 is the hash of the calldata which the group approves. This data is dependant
	 * 	on the marketplace / dex where the group are approving the transaction.
	 */
	mapping(address => mapping(bytes32 => uint256)) private contractSignatureAllowance;
	mapping(address => bool) public extensions;
	mapping(uint256 => Proposal) public proposals;
	mapping(ProposalType => VoteType) public proposalVoteTypes;
	mapping(uint256 => mapping(address => bool)) public voted;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	function init(
		string memory name_,
		string memory symbol_,
		address[] memory voters_,
		address[2] memory extensions_,
		uint32[4] memory govSettings_
	) public payable virtual nonReentrant {
		if (votingPeriod != 0) revert Initialized();

		if (govSettings_[0] == 0 || govSettings_[0] > 365 days) revert PeriodBounds();

		if (govSettings_[1] > 1 days) revert PeriodBounds();

		if (govSettings_[2] < 1 || govSettings_[2] > 100) revert MemberLimitExceeded();

		if (govSettings_[3] < 52 || govSettings_[3] > 100) revert SupermajorityBounds();

		TableGovernance._init(name_, symbol_, voters_);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = extensions_[0];

		// Set the fundraise extension to true - allows it to mint shares
		extensions[extensions_[1]] = true;

		memberCount = voters_.length;

		votingPeriod = govSettings_[0];

		gracePeriod = govSettings_[1];

		memberVoteThreshold = govSettings_[2];

		supermajority = govSettings_[3];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
	}

	/// ----------------------------------------------------------------------------------------
	///							PROPOSAL LOGIC
	/// ----------------------------------------------------------------------------------------

	function getProposalArrays(uint256 proposal)
		public
		view
		virtual
		returns (
			address[] memory accounts,
			uint256[] memory amounts,
			bytes[] memory payloads
		)
	{
		Proposal storage prop = proposals[proposal];

		(accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
	}

	function propose(
		ProposalType proposalType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) public virtual nonReentrant returns (uint256 proposal) {
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (proposalType == ProposalType.VPERIOD)
			if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

		if (proposalType == ProposalType.GPERIOD)
			if (amounts[0] > 1 days) revert PeriodBounds();

		if (proposalType == ProposalType.MEMBER_THRESHOLD)
			if (amounts[0] == 0 || amounts[0] > 100) revert MemberLimitExceeded();

		if (proposalType == ProposalType.SUPERMAJORITY)
			if (amounts[0] < 52 || amounts[0] > 100) revert SupermajorityBounds();

		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 14 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		if (proposalType == ProposalType.MINT)
			if ((memberCount + accounts.length) > 12) revert MemberLimitExceeded();

		bool selfSponsor;

		// Cannot realistically overflow on human timescales
		unchecked {
			// If member or extension is making proposal, include sponsorship
			if (balanceOf[msg.sender][MEMBERSHIP] != 0 || extensions[msg.sender]) {
				++currentActiveProposalCount;
				selfSponsor = true;
			}

			++proposalCount;
		}

		proposal = proposalCount;

		proposals[proposal] = Proposal({
			proposalType: proposalType,
			accounts: accounts,
			amounts: amounts,
			payloads: payloads,
			yesVotes: 0,
			creationTime: selfSponsor ? _safeCastTo32(block.timestamp) : 0,
			proposer: msg.sender
		});

		emit NewProposal(msg.sender, proposal, proposalType, accounts, amounts, payloads);
	}

	function sponsorProposal(uint256 proposal) public virtual nonReentrant {
		Proposal storage prop = proposals[proposal];

		if (balanceOf[msg.sender][MEMBERSHIP] == 0) revert NotMember();

		if (prop.proposer == address(0)) revert NotCurrentProposal();

		if (prop.creationTime != 0) revert Sponsored();

		prop.creationTime = _safeCastTo32(block.timestamp);

		++currentActiveProposalCount;

		emit ProposalSponsored(msg.sender, proposal);
	}

	function vote(uint256 proposal) public virtual nonReentrant {
		_vote(msg.sender, proposal);
	}

	function voteBySig(
		address signer,
		uint256 proposal,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual nonReentrant {
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(VOTE_HASH, signer, proposal))
			)
		);

		address recoveredAddress = ecrecover(digest, v, r, s);

		if (recoveredAddress == address(0) || recoveredAddress != signer) revert InvalidSignature();

		_vote(signer, proposal);
	}

	function _vote(address signer, uint256 proposal) internal virtual {
		Proposal memory prop = proposals[proposal];

		if (balanceOf[signer][MEMBERSHIP] == 0) revert NotMember();

		if (voted[proposal][signer]) revert AlreadyVoted();

		// This is safe from overflow because `votingPeriod` is capped so it will not combine
		// with unix time to exceed the max uint256 value
		unchecked {
			if (block.timestamp > prop.creationTime + votingPeriod) {
				revert NotVoteable();
			}
		}

		uint96 weight;

		if (proposalVoteTypes[prop.proposalType] == VoteType.MEMBER) weight = 1;
		else {
			// If the delegation extension is not set, use token balance as weight
			// Else get voting balance from delegator, where the '0' encoded means type 0 ie. Get Balance
			if (delegationExtension == address(0)) {
				weight = uint96(balanceOf[signer][TOKEN]);
			} else {
				(, uint256 amount) = IForumGroupExtension(delegationExtension).callExtension(
					address(this),
					0,
					abi.encode(address(this), signer, address(0), prop.creationTime, 0)
				);
				weight = uint96(amount);
			}
		}

		// This is safe from overflow because `yesVotes` is capped by `totalSupply`
		// which is checked for overflow in `ForumGovernance` contract
		unchecked {
			proposals[proposal].yesVotes += weight;
		}

		voted[proposal][signer] = true;

		emit VoteCast(signer, proposal);
	}

	function processProposal(uint256 proposal)
		public
		virtual
		nonReentrant
		returns (bool didProposalPass, bytes[] memory results)
	{
		Proposal storage prop = proposals[proposal];

		VoteType voteType = proposalVoteTypes[prop.proposalType];

		if (prop.creationTime == 0) revert NotCurrentProposal();

		// This is safe from overflow because `votingPeriod` is capped so it will not combine
		// with unix time to exceed the max uint256 value.
		// If gracePeriod is set to 0 we do not wait, instead proposal is processed when ready
		// allowing for faster execution.
		unchecked {
			if (gracePeriod != 0 && block.timestamp <= prop.creationTime + votingPeriod + gracePeriod)
				revert VotingNotEnded();
		}

		didProposalPass = _countVotes(voteType, prop.yesVotes);

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (prop.proposalType == ProposalType.MINT)
					for (uint256 i; i < prop.accounts.length; ) {
						_mint(prop.accounts[i], MEMBERSHIP, 1, '');
						_mint(prop.accounts[i], TOKEN, prop.amounts[i], '');

						++memberCount;
						++i;
					}

				if (prop.proposalType == ProposalType.BURN)
					for (uint256 i; i < prop.accounts.length; ) {
						_burn(prop.accounts[i], MEMBERSHIP, 1);
						_burn(prop.accounts[i], TOKEN, prop.amounts[i]);

						--memberCount;
						++i;
					}

				if (prop.proposalType == ProposalType.CALL) {
					uint256 value;

					for (uint256 i; i < prop.accounts.length; i++) {
						results = new bytes[](prop.accounts.length);

						value += IExecutionManager(pfpExtension).manageExecution(
							prop.accounts[i],
							prop.amounts[i],
							prop.payloads[i]
						);

						(, bytes memory result) = prop.accounts[i].call{value: prop.amounts[i]}(
							prop.payloads[i]
						);

						results[i] = result;
					}
					// Send the commission calculated in the executionManger
					(bool success, ) = pfpExtension.call{value: value}('');
					if (!success) revert CallError();
				}

				// Governance settings
				if (prop.proposalType == ProposalType.VPERIOD) votingPeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.GPERIOD) gracePeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_THRESHOLD)
					memberVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.SUPERMAJORITY)
					supermajority = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TYPE)
					proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);

				if (prop.proposalType == ProposalType.PAUSE) _flipPause();

				if (prop.proposalType == ProposalType.EXTENSION)
					for (uint256 i; i < prop.accounts.length; i++) {
						if (prop.amounts[i] != 0) extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
					}

				if (prop.proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (prop.proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

				if (prop.proposalType == ProposalType.DELEGATION) {
					// Delegation can not be set if there are any active proposals (apart from the proposal to enable delegation)
					if (currentActiveProposalCount != 1) revert NotCurrentProposal();

					delegationExtension = delegationExtension != address(0) ? address(0) : prop.accounts[0];
					IForumGroupExtension(prop.accounts[0]).setExtension(prop.payloads[0]);
				}

				if (prop.proposalType == ProposalType.PFP) {
					// Call the NFTContract to approve the PfpStaker to transfer the token
					(bool success, ) = prop.accounts[0].call(prop.payloads[0]);
					if (!success) revert PFPFailed();

					IPfpStaker(pfpExtension).stakeNFT(address(this), prop.accounts[0], prop.amounts[0]);
				}

				if (prop.proposalType == ProposalType.ALLOW_CONTRACT_SIG) {
					// This sets the allowance for EIP-1271 contract signature transactions on marketplaces
					for (uint256 i; i < prop.accounts.length; i++) {
						contractSignatureAllowance[prop.accounts[i]][bytes32(prop.payloads[i])] = 1;
					}
				}
				// Reduce active proposal count, and delete proposal now that it has been processed
				--currentActiveProposalCount;
				delete proposals[proposal];

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);
			}
		} else {
			// Only delete and update the proposal settings if there are not enough votes AND the time limit has passed
			// This prevents deleting proposals unfairly
			if (block.timestamp > prop.creationTime + votingPeriod + gracePeriod) {
				--currentActiveProposalCount;
				delete proposals[proposal];

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);
			}
		}
	}

	function _countVotes(VoteType voteType, uint256 yesVotes) internal view virtual returns (bool) {
		// Fail proposal if no participation
		if (yesVotes == 0) return false;

		if (voteType == VoteType.MEMBER)
			if ((yesVotes * 100) / memberCount >= memberVoteThreshold) return true;

		if (voteType == VoteType.SIMPLE_MAJORITY)
			if (yesVotes > (((totalSupply) * 50) / 100)) return true;

		if (voteType == VoteType.SUPERMAJORITY)
			if (yesVotes >= ((totalSupply) * supermajority) / 100) return true;

		revert NotVoteable();
	}

	/// ----------------------------------------------------------------------------------------
	///							EXTENSIONS
	/// ----------------------------------------------------------------------------------------

	modifier onlyExtension() {
		if (!extensions[msg.sender]) revert NotExtension();

		_;
	}

	function callExtension(
		address extension,
		uint256 amount,
		bytes calldata extensionData
	) public payable virtual nonReentrant returns (bool mint, uint256 amountOut) {
		if (!extensions[extension]) revert NotExtension();

		(mint, amountOut) = IForumGroupExtension(extension).callExtension{value: msg.value}(
			msg.sender,
			amount,
			extensionData
		);

		if (mint) {
			if (amountOut != 0) _mint(msg.sender, TOKEN, amountOut, '');
		} else {
			if (amountOut != 0) _burn(msg.sender, TOKEN, amount);
		}
	}

	function mintShares(
		address to,
		uint256 id,
		uint256 amount
	) public virtual onlyExtension {
		_mint(to, id, amount, '');
	}

	function burnShares(
		address from,
		uint256 id,
		uint256 amount
	) public virtual onlyExtension {
		_burn(from, id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///							UTILITIES
	/// ----------------------------------------------------------------------------------------

	// 'id' not used but included to keep function signature that of ERC1155
	function uri(uint256) public view override returns (string memory) {
		return IPfpStaker(pfpExtension).getURI(address(this));
	}

	function isValidSignature(bytes32 hash, bytes memory signature)
		public
		view
		override
		returns (bytes4)
	{
		// Decode signture
		if (signature.length != 65) revert SignatureError();

		uint8 v;
		bytes32 r;
		bytes32 s;

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := and(mload(add(signature, 65)), 255)
		}

		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
			revert SignatureError();

		if (!(v == 27 || v == 28)) revert SignatureError();

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);

		/**
		 * The group must pass a proposal to allow the contract to be used to sign transactions
		 * Once passed contractSignatureAllowance will be set true for the exact transaction hash
		 */
		// TODO CONSIDER ADDING A NONCE OF THE SENDER TO THE HASH
		if (contractSignatureAllowance[msg.sender][hash] == 0) revert SignatureError();

		// Verify signer is member
		if (balanceOf[signer][MEMBERSHIP] != 0) {
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}

	receive() external payable virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import '../interfaces/IForumGroupExtension.sol';

/// @notice Minimalist and gas efficient ERC1155 based DAO implementation with governance.
/// @author Modified from KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/KaliDAOtoken.sol)
abstract contract TableGovernance {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event URI(string value, uint256 indexed id);

	event PauseFlipped(bool paused);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Paused();

	error SignatureExpired();

	error InvalidSignature();

	error Uint32max();

	error Uint96max();

	/// ----------------------------------------------------------------------------------------
	///							METADATA STORAGE
	/// ----------------------------------------------------------------------------------------

	string public name;

	string public symbol;

	uint8 public constant decimals = 18;

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 STORAGE
	/// ----------------------------------------------------------------------------------------

	uint256 public totalSupply;

	uint256 public votingSupply;

	mapping(address => mapping(uint256 => uint256)) public balanceOf;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/// ----------------------------------------------------------------------------------------
	///							EIP-2612 STORAGE
	/// ----------------------------------------------------------------------------------------

	bytes32 public constant PERMIT_TYPEHASH =
		keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

	uint256 internal INITIAL_CHAIN_ID;

	mapping(address => uint256) public nonces;

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	address public delegationExtension;

	bool public paused;

	// Membership NFT
	uint256 internal constant MEMBERSHIP = 0;
	// DAO token representing voting share of treasury
	uint256 internal constant TOKEN = 1;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	function _init(
		string memory name_,
		string memory symbol_,
		address[] memory voters_
	) internal virtual {
		name = name_;

		symbol = symbol_;

		paused = true;

		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

		// Voters limited to 12 by a check in the factory
		unchecked {
			uint256 votersLen = voters_.length;

			// Mint membership for initial members
			for (uint256 i; i < votersLen; i++) {
				_mint(voters_[i], MEMBERSHIP, 1, '');
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							METADATA LOGIC
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 id) public view virtual returns (string memory);

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 LOGIC
	/// ----------------------------------------------------------------------------------------

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual notPaused {
		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		balanceOf[from][id] -= amount;
		balanceOf[to][id] += amount;

		if (id == TOKEN) {
			if (delegationExtension != address(0)) {
				IForumGroupExtension(delegationExtension).callExtension(
					from,
					amount,
					abi.encode(address(this), from, to, uint32(0), 1)
				); // 1 indicates type 1 in delegator extension, this updates vote balance
			}
		}

		emit TransferSingle(msg.sender, from, to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual notPaused {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		for (uint256 i = 0; i < idsLength; ) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			if (id == TOKEN) {
				if (delegationExtension != address(0)) {
					IForumGroupExtension(delegationExtension).callExtension(
						from,
						amount,
						abi.encode(address(this), from, to, uint32(0), 1)
					); // 1 indicates type 1 in delegator extension, this updates vote balance
				}
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
					ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function balanceOfBatch(address[] memory owners, uint256[] memory ids)
		public
		view
		virtual
		returns (uint256[] memory balances)
	{
		uint256 ownersLength = owners.length; // Saves MLOADs.

		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

		balances = new uint256[](owners.length);

		// Unchecked because the only math done is incrementing
		// the array index counter which cannot possibly overflow.
		unchecked {
			for (uint256 i = 0; i < ownersLength; i++) {
				balances[i] = balanceOf[owners[i]][ids[i]];
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							EIP-2612 LOGIC
	/// ----------------------------------------------------------------------------------------

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
					keccak256(bytes(name)),
					keccak256('1'),
					block.chainid,
					address(this)
				)
			);
	}

	/// ----------------------------------------------------------------------------------------
	///							DAO LOGIC
	/// ----------------------------------------------------------------------------------------

	modifier notPaused() {
		if (paused) revert Paused();
		_;
	}

	/// ----------------------------------------------------------------------------------------
	///							ERC-165 LOGIC
	/// ----------------------------------------------------------------------------------------

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
			interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
	}

	/// ----------------------------------------------------------------------------------------
	///						INTERNAL MINT/BURN  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal {
		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value
		unchecked {
			balanceOf[to][id] += amount;
		}

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			// If delegation is enabled, also update vote balances on delegator
			// The 1 encoded to callExtension indicates type 1 in delegator extension,
			// this sets vote balance for minting and burning
			if (delegationExtension != address(0)) {
				IForumGroupExtension(delegationExtension).callExtension(
					msg.sender,
					amount,
					abi.encode(address(this), address(0), to, uint32(0), 1)
				);
			}
			totalSupply += amount;
		}

		emit TransferSingle(msg.sender, address(0), to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchMint(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[to][ids[i]] += amounts[i];

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				// If delegation is enabled, also update vote balances on delegator
				// The 1 encoded to callExtension indicates type 1 in delegator extension,
				// this sets vote balance for minting and burning
				if (delegationExtension != address(0)) {
					IForumGroupExtension(delegationExtension).callExtension(
						msg.sender,
						amounts[i],
						abi.encode(address(this), address(0), to, uint32(0), 1)
					);
				}
				totalSupply += amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					address(0),
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchBurn(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[from][ids[i]] -= amounts[i];

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				// The 1 encoded to callExtension indicates type 1 in delegator extension,
				// this sets vote balance for minting and burning
				if (delegationExtension != address(0)) {
					IForumGroupExtension(delegationExtension).callExtension(
						msg.sender,
						amounts[i],
						abi.encode(address(this), from, address(0), uint32(0), 1)
					);
				}
				totalSupply -= amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal {
		balanceOf[from][id] -= amount;

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			// The 1 encoded to callExtension indicates type 1 in delegator extension,
			// this sets vote balance for minting and burning
			if (delegationExtension != address(0)) {
				IForumGroupExtension(delegationExtension).callExtension(
					msg.sender,
					amount,
					abi.encode(address(this), from, address(0), uint32(0), 1)
				);
			}
			totalSupply -= amount;
		}

		emit TransferSingle(msg.sender, from, address(0), id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///						PAUSE  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _flipPause() internal virtual {
		paused = !paused;

		emit PauseFlipped(paused);
	}

	/// ----------------------------------------------------------------------------------------
	///						SAFECAST  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
		if (x > type(uint32).max) revert Uint32max();

		return uint32(x);
	}

	function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
		if (x > type(uint96).max) revert Uint96max();

		return uint96(x);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
	function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
		results = new bytes[](data.length);

		// cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 0; i < data.length; i++) {
				(bool success, bytes memory result) = address(this).delegatecall(data[i]);

				if (!success) {
					if (result.length < 68) revert();

					assembly {
						result := add(result, 0x04)
					}

					revert(abi.decode(result, (string)));
				}
				results[i] = result;
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Receiver hook utility for NFT 'safe' transfers
/// @author Author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/utils/NFTreceiver.sol)
abstract contract NFTreceiver {
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0x150b7a02;
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xbc197c81;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from KaliDAO (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
	error Reentrancy();

	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		//require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
		if (_status == _ENTERED) revert Reentrancy();

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice ForumGroup interface for sharing types
interface IForumGroupTypes {
	enum ProposalType {
		MINT, // add membership
		BURN, // revoke membership
		CALL, // call contracts
		VPERIOD, // set `votingPeriod`
		GPERIOD, // set `gracePeriod`
		MEMBER_THRESHOLD, // set `memberVoteThreshold`
		SUPERMAJORITY, // set `supermajority`
		TYPE, // set `VoteType` to `ProposalType`
		PAUSE, // flip membership transferability
		EXTENSION, // flip `extensions` whitelisting
		ESCAPE, // delete pending proposal in case of revert
		DOCS, // amend org docs
		DELEGATION, // enable delegation
		PFP, // change the group pfp
		ALLOW_CONTRACT_SIG // enable the contract to sign as an EOA
	}

	enum VoteType {
		MEMBER,
		SIMPLE_MAJORITY,
		SUPERMAJORITY
	}

	/// @dev AccountMetadata is created by shifting uint16 values into a single uint256.
	/// It stores info we use to determine commissions on trade or how to handle proposals to external contracts
	struct Proposal {
		ProposalType proposalType;
		address[] accounts; // member(s) being added/kicked; account(s) receiving payload
		uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
		bytes[] payloads; // data for CALL proposals
		uint96 yesVotes;
		uint32 creationTime;
		address proposer;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice ForumGroup membership extension interface.
/// @author modified from KaliDAO.
interface IForumGroupExtension {
	function setExtension(bytes calldata extensionData) external;

	function callExtension(
		address account,
		uint256 amount,
		bytes calldata extensionData
	) external payable returns (bool mint, uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp - defaults to shield
interface IPfpStaker {
	struct StakedPFP {
		address NFTcontract;
		uint256 tokenId;
	}

	function stakeInitialShield(address, uint256) external;

	function stakeNFT(
		address,
		address,
		uint256
	) external;

	function getURI(address) external view returns (string memory nftURI);

	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 * @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/interfaces/IERC1271.sol)
 * _Available since v4.1._
 */
interface IERC1271 {
	/**
	 * @dev Should return whether the signature provided is valid for the provided data
	 * @param hash      Hash of the data to be signed
	 * @param signature Signature byte array associated with _data
	 */
	function isValidSignature(bytes32 hash, bytes memory signature)
		external
		view
		returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice Execution Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

import {IForumGroupTypes} from '../interfaces/IForumGroupTypes.sol';

interface IExecutionManager {
	function addProposalHandler(address newHandledAddress, address handlerAddress) external;

	function updateProposalHandler(address proposalHandler, address newProposalHandler) external;

	function manageExecution(
		address target,
		uint256 value,
		bytes memory payload
	) external returns (uint256);
}