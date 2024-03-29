// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {SafeTransferLib} from '../../../libraries/SafeTransferLib.sol';

import {ReentrancyGuard} from '../../../utils/ReentrancyGuard.sol';

import {IForumGroup} from '../../../interfaces/IForumGroup.sol';

/**
 * @title ForumGroupFundraise
 * @notice Contract that implements a round of fundraising from all DAO members
 * @dev Version 1 - AVAX only fundraise. All members must contribute
 */
contract ForumGroupFundraise is ReentrancyGuard {
	using SafeTransferLib for address;

	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewFundContribution(address indexed groupAddress, address indexed proposer, uint256 value);

	event FundRoundCancelled(address indexed groupAddress);

	event FundRoundReleased(
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

	// valueNumerator and valueDenominator combine to form unitValue of treasury tokens
	// This is used to determin how many token to mint for eac contributor
	struct Fund {
		address[] contributors;
		uint256 individualContribution;
		uint256 valueNumerator;
		uint256 valueDenominator;
	}

	uint256 private constant MEMBERSHIP = 0;
	uint256 private constant TOKEN = 1;

	mapping(address => Fund) private funds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	/**
	 * @notice Initiate a round of fundraising
	 * @param groupAddress Address of group
	 */
	function initiateFundRound(
		address groupAddress,
		uint256 valueNumerator,
		uint256 valueDenominator
	) public payable virtual nonReentrant {
		// Only members can start a fund.
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		if (funds[groupAddress].individualContribution != 0) revert OpenFund();

		// No gas saving to use Fund({}) format, and since we need to push to the arry, we assign each element individually.
		funds[groupAddress].contributors.push(msg.sender);
		funds[groupAddress].individualContribution = msg.value;
		funds[groupAddress].valueNumerator = valueNumerator;
		funds[groupAddress].valueDenominator = valueDenominator;
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Submit a fundraise contribution
	 * @param groupAddress Address of group
	 */
	function submitFundContribution(address groupAddress) public payable virtual nonReentrant {
		// Only members can contribute to the fund
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		// Can only contribute once per fund
		if (contributionTracker[groupAddress][msg.sender]) revert IncorrectContribution();

		if (msg.value != funds[groupAddress].individualContribution) revert IncorrectContribution();

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		funds[groupAddress].contributors.push(msg.sender);
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Cancel a fundraise and return funds to contributors
	 * @param groupAddress Address of group
	 */
	function cancelFundRound(address groupAddress) public virtual nonReentrant {
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

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

		emit FundRoundCancelled(groupAddress);
	}

	/**
	 * @notice Process the fundraise, sending AVAX to group and minting tokens to contributors
	 * @param groupAddress Address of group
	 */
	function processFundRound(address groupAddress) public virtual nonReentrant {
		Fund memory fund = funds[groupAddress];

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		uint256 memberCount = fund.contributors.length;

		// We adjust the number of shares distributed based on the unitValue of group tokens
		// This ensures that members get a fair number of tokens given the value of the treasury at any time
		uint256 adjustedContribution = (fund.individualContribution * fund.valueDenominator) /
			fund.valueNumerator;

		if (memberCount != IForumGroup(groupAddress).memberCount()) revert MembersMissing();

		groupAddress._safeTransferETH(fund.individualContribution * memberCount);

		for (uint256 i; i < memberCount; ) {
			// Mint member an share of tokens equal to their contribution and reset their status in the tracker
			IForumGroup(groupAddress).mintShares(fund.contributors[i], TOKEN, adjustedContribution);
			contributionTracker[groupAddress][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[groupAddress];

		emit FundRoundReleased(groupAddress, fund.contributors, fund.individualContribution);
	}

	/**
	 * @notice Get the details of a fundraise
	 * @param groupAddress Address of group
	 * @return fundDetails The fundraise requested
	 */
	function getFund(address groupAddress) public view returns (Fund memory fundDetails) {
		return funds[groupAddress];
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./IForumGroupTypes.sol";

/// @notice ForumGroup interface
interface IForumGroup {
    function balanceOf(address to, uint256 tokenId)
        external
        payable
        returns (uint256);

    function propose(
        IForumGroupTypes.ProposalType proposalType,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    )
        external
        payable
        returns (uint256);

    function proposalCount() external payable returns (uint256);

    function memberCount() external payable returns (uint256);

    function mintShares(address to, uint256 id, uint256 amount)
        external
        payable;

    function burnShares(address from, uint256 id, uint256 amount)
        external
        payable;
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
        MEMBER_LIMIT, // set `memberLimit`
        MEMBER_THRESHOLD, // set `memberVoteThreshold`
        TOKEN_THRESHOLD, // set `tokenVoteThreshold`
        TYPE, // set `VoteType` to `ProposalType`
        PAUSE, // flip membership transferability
        EXTENSION, // flip `extensions` whitelisting
        ESCAPE, // delete pending proposal in case of revert
        DOCS, // amend org docs
        PFP, // change the group pfp
        ALLOW_CONTRACT_SIG // enable the contract to sign as an EOA
    }

    enum VoteType {
        MEMBER, // % of members required to pass
        SIMPLE_MAJORITY, // over 50% total votes required to pass
        TOKEN_MAJORITY // user set % of total votes required to pass
    }

    struct Proposal {
        ProposalType proposalType;
        address[] accounts; // member(s) being added/kicked; account(s) receiving payload
        uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
        bytes[] payloads; // data for CALL proposals
        uint32 creationTime; // timestamp of proposal creation
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
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
pragma solidity ^0.8.13;

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