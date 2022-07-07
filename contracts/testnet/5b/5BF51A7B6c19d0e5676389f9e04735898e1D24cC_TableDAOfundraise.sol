// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import '../../../utils/ReentrancyGuard.sol';

import {IRoundtableDAO} from '../../../interfaces/IRoundtableDAO.sol';

/// @notice Contract that implements a round of fundraising from all DAO members.
/// @notice Version 1 - AVAX fundraise only. All members must contribute

contract TableDAOfundraise is ReentrancyGuard {
	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewFundContribution(address indexed dao, address indexed proposer, uint256 value);

	event FundProposalCancelled(address indexed dao);

	event FundProposalReleased(
		address indexed dao,
		address[] contributors,
		uint256 individualContribution
	);

	/// -----------------------------------------------------------------------
	/// Errors
	/// -----------------------------------------------------------------------

	error NotProposer();

	error NotMember();

	error MembersMissing();

	error FundraiseMissing();

	error IncorrectContribution();

	error OpenFund();

	error DeadlinePassed();

	/// -----------------------------------------------------------------------
	/// Fundraise Storage
	/// -----------------------------------------------------------------------

	struct Fund {
		address[] contributors;
		uint256 individualContribution;
	}

	mapping(address => Fund) private funds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	function submitFundProposal(address dao) public payable virtual nonReentrant {
		// Only members can start a fund.
		if (IRoundtableDAO(dao).balanceOf(msg.sender, 0) == 0) revert NotMember();

		if (funds[dao].individualContribution != 0) revert OpenFund();

		funds[dao].contributors.push(msg.sender);
		funds[dao].individualContribution = msg.value;
		contributionTracker[dao][msg.sender] = true;

		emit NewFundContribution(dao, msg.sender, msg.value);
	}

	function submitFundContribution(address dao) public payable virtual nonReentrant {
		// Only members can contribute to the fund.
		if (IRoundtableDAO(dao).balanceOf(msg.sender, 0) == 0) revert NotMember();

		// Can only contribute once per fund.
		if (contributionTracker[dao][msg.sender]) revert IncorrectContribution();

		Fund storage fund = funds[dao];

		if (msg.value != fund.individualContribution) revert IncorrectContribution();

		if (funds[dao].individualContribution == 0) revert FundraiseMissing();

		funds[dao].contributors.push(msg.sender);
		contributionTracker[dao][msg.sender] = true;

		emit NewFundContribution(dao, msg.sender, msg.value);
	}

	function cancelFundProposal(address dao) public virtual nonReentrant {
		if (IRoundtableDAO(dao).balanceOf(msg.sender, 0) == 0) revert NotMember();

		Fund storage fund = funds[dao];

		// Only dao or proposer can cancel the fundraise.
		if (!(msg.sender == dao || msg.sender == fund.contributors[0])) revert NotProposer();

		// Return funds from escrow
		for (uint256 i; i < fund.contributors.length; ) {
			payable(fund.contributors[i]).transfer(fund.individualContribution);
			contributionTracker[dao][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[dao];

		emit FundProposalCancelled(dao);
	}

	function processFundProposal(address dao) public virtual nonReentrant {
		Fund storage fund = funds[dao];

		if (funds[dao].individualContribution == 0) revert FundraiseMissing();

		uint256 memberCount = fund.contributors.length;

		if (memberCount != IRoundtableDAO(dao).memberCount()) revert MembersMissing();

		payable(dao).transfer(fund.individualContribution * memberCount);

		for (uint256 i; i < memberCount; ) {
			// Mint member an share of tokens equal to their contribution and reset their status in the tracker
			IRoundtableDAO(dao).mintShares(fund.contributors[i], 1, fund.individualContribution);
			contributionTracker[dao][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[dao];

		emit FundProposalReleased(dao, fund.contributors, fund.individualContribution);
	}

	function getFund(address dao)
		public
		view
		returns (address[] memory contributors, uint256 individualContribution)
	{
		Fund storage fund = funds[dao];

		contributors = fund.contributors;
		individualContribution = fund.individualContribution;
	}
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