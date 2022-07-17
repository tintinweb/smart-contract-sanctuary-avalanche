// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {SafeTransferLib} from '../../../libraries/SafeTransferLib.sol';

import {ReentrancyGuard} from '../../../utils/ReentrancyGuard.sol';

import {IRoundtableDAO} from '../../../interfaces/IRoundtableDAO.sol';

/**
 * @title TableDAOfundraise
 * @notice Contract that implements a round of fundraising from all DAO members
 * @dev Version 1 - AVAX only fundraise. All members must contribute
 */
contract TableDAOfundraise is ReentrancyGuard {
	using SafeTransferLib for address;

	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewFundContribution(address indexed groupAddress, address indexed proposer, uint256 value);

	event FundProposalCancelled(address indexed groupAddress);

	event FundProposalReleased(
		address indexed groupAddress,
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

	/// -----------------------------------------------------------------------
	/// Fundraise Storage
	/// -----------------------------------------------------------------------

	struct Fund {
		address[] contributors;
		uint256 individualContribution;
	}

	uint256 private constant MEMBERSHIP = 0;
	uint256 private constant TOKEN = 1;

	mapping(address => Fund) private funds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	/**
	 * @notice Submit a proposal for a fundraise
	 * @param groupAddress Address of group
	 */
	function submitFundProposal(address groupAddress) public payable virtual nonReentrant {
		// Only members can start a fund.
		if (IRoundtableDAO(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		if (funds[groupAddress].individualContribution != 0) revert OpenFund();

		funds[groupAddress].contributors.push(msg.sender);
		funds[groupAddress].individualContribution = msg.value;
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Submit a fundraise contribution
	 * @param groupAddress Address of group
	 */
	function submitFundContribution(address groupAddress) public payable virtual nonReentrant {
		// Only members can contribute to the fund
		if (IRoundtableDAO(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		// Can only contribute once per fund
		if (contributionTracker[groupAddress][msg.sender]) revert IncorrectContribution();

		Fund storage fund = funds[groupAddress];

		if (msg.value != fund.individualContribution) revert IncorrectContribution();

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		funds[groupAddress].contributors.push(msg.sender);
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Cancel a fundraise and return funds to contributors
	 * @param groupAddress Address of group
	 */
	function cancelFundProposal(address groupAddress) public virtual nonReentrant {
		if (IRoundtableDAO(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		Fund storage fund = funds[groupAddress];

		// Only groupAddress or proposer can cancel the fundraise.
		if (!(msg.sender == groupAddress || msg.sender == fund.contributors[0])) revert NotProposer();

		// Return funds from escrow
		for (uint256 i; i < fund.contributors.length; ) {
			payable(fund.contributors[i]).transfer(fund.individualContribution);
			contributionTracker[groupAddress][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[groupAddress];

		emit FundProposalCancelled(groupAddress);
	}

	/**
	 * @notice Process the fundraise, sending AVAX to group and minting tokens to contributors
	 * @param groupAddress Address of group
	 */
	function processFundProposal(address groupAddress) public virtual nonReentrant {
		Fund storage fund = funds[groupAddress];

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		uint256 memberCount = fund.contributors.length;

		if (memberCount != IRoundtableDAO(groupAddress).memberCount()) revert MembersMissing();

		groupAddress._safeTransferETH(fund.individualContribution * memberCount);

		for (uint256 i; i < memberCount; ) {
			// Mint member an share of tokens equal to their contribution and reset their status in the tracker
			IRoundtableDAO(groupAddress).mintShares(
				fund.contributors[i],
				TOKEN,
				fund.individualContribution
			);
			contributionTracker[groupAddress][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[groupAddress];

		emit FundProposalReleased(groupAddress, fund.contributors, fund.individualContribution);
	}

	/**
	 * @notice Get the details of a fundraise
	 * @param groupAddress Address of group
	 * @return contributors Array of contributors
	 * @return individualContribution Individual contribution of each contributor
	 */
	function getFund(address groupAddress)
		public
		view
		returns (address[] memory contributors, uint256 individualContribution)
	{
		Fund storage fund = funds[groupAddress];

		contributors = fund.contributors;
		individualContribution = fund.individualContribution;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values.
/// @author Modified from KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/libraries/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
	/*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

	error ETHtransferFailed();

	error TransferFailed();

	error TransferFromFailed();

	/*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

	function _safeTransferETH(address to, uint256 amount) internal {
		bool callStatus;

		assembly {
			// transfer the ETH and store if it succeeded or not
			callStatus := call(gas(), to, amount, 0, 0, 0, 0)
		}

		if (!callStatus) revert ETHtransferFailed();
	}

	/*///////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

	function _safeTransfer(
		address token,
		address to,
		uint256 amount
	) internal {
		bool callStatus;

		assembly {
			// get a pointer to some free memory
			let freeMemoryPointer := mload(0x40)

			// write the abi-encoded calldata to memory piece by piece:
			mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // begin with the function selector

			mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument

			mstore(add(freeMemoryPointer, 36), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

			// call the token and store if it succeeded or not
			// we use 68 because the calldata length is 4 + 32 * 2
			callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
		}

		if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFailed();
	}

	function _safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 amount
	) internal {
		bool callStatus;

		assembly {
			// get a pointer to some free memory
			let freeMemoryPointer := mload(0x40)

			// write the abi-encoded calldata to memory piece by piece:
			mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // begin with the function selector

			mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "from" argument

			mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument

			mstore(add(freeMemoryPointer, 68), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

			// call the token and store if it succeeded or not
			// we use 100 because the calldata length is 4 + 32 * 3
			callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
		}

		if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFromFailed();
	}

	/*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

	function _didLastOptionalReturnCallSucceed(bool callStatus) internal pure returns (bool success) {
		assembly {
			// get how many bytes the call returned
			let returnDataSize := returndatasize()

			// if the call reverted:
			if iszero(callStatus) {
				// copy the revert message into memory
				returndatacopy(0, 0, returnDataSize)

				// revert with the same message
				revert(0, returnDataSize)
			}

			switch returnDataSize
			case 32 {
				// copy the return data into memory
				returndatacopy(0, 0, returnDataSize)

				// set success to whether it returned true
				success := iszero(iszero(mload(0)))
			}
			case 0 {
				// there was no return data
				success := 1
			}
			default {
				// it returned some malformed input
				success := 0
			}
		}
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