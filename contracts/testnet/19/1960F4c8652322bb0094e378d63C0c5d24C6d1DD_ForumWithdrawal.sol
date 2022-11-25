// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

/// @dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalTransferManager {
    function buildApprovalPayloads(address collection, uint256 amountOrId)
        external
        view
        returns (bytes memory);

    function executeTransferPayloads(
        address collection,
        address from,
        address to,
        uint256 amountOrId
    )
        external;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

import {IERC20} from "../interfaces/IERC20.sol"; // consider minimal version
import {IForumGroup, IForumGroupTypes} from "../interfaces/IForumGroup.sol";
import {IWithdrawalTransferManager} from
    "../interfaces/IWithdrawalTransferManager.sol";

import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

/// @notice Withdrawal contract that transfers registered tokens from Forum group in proportion to burnt DAO tokens.
contract ForumWithdrawal is ReentrancyGuard {
    using SafeTransferLib for address;

    /// ----------------------------------------------------------------------------------------
    /// Events
    /// ----------------------------------------------------------------------------------------

    event ExtensionSet(
        address indexed group, address[] tokens, uint256 indexed withdrawalStart
    );

    event ExtensionCalled(
        address indexed group,
        address indexed member,
        uint256 indexed amountBurned
    );

    event CustomWithdrawalAdded(
        address indexed withdrawer,
        address indexed group,
        uint256 indexed proposal,
        uint256 amount
    );

    event CustomWithdrawalProcessed(
        address indexed withdrawer, address indexed group, uint256 amount
    );

    event TokensAdded(address indexed group, address[] tokens);

    event TokensRemoved(address indexed group, uint256[] tokenIndex);

    /// ----------------------------------------------------------------------------------------
    ///							ERRORS
    /// ----------------------------------------------------------------------------------------

    error NullTokens();

    error NotStarted();

    error NotMember();

    error NoArrayParity();

    /// ----------------------------------------------------------------------------------------
    /// Withdrawl Storage
    /// ----------------------------------------------------------------------------------------

    struct CustomWithdrawal {
        address[] tokens;
        uint256[] amountOrId;
        uint256 amountToBurn;
    }

    IWithdrawalTransferManager public withdrawalTransferManager;

    // Pre-set assets which can be redeemed at any point by members
    mapping(address => address[]) public withdrawables;
    // Start time for withdrawals
    mapping(address => uint256) public withdrawalStarts;
    // Custom withdrawals proposed to a group by a member (group, member, CustomWithdrawal)
    mapping(address => mapping(address => CustomWithdrawal)) private
        customWithdrawals;

    /// ----------------------------------------------------------------------------------------
    /// Constructor
    /// ----------------------------------------------------------------------------------------

    constructor(address _withdrawalTransferManager) {
        withdrawalTransferManager =
            IWithdrawalTransferManager(_withdrawalTransferManager);
    }

    /// ----------------------------------------------------------------------------------------
    /// Withdrawal Logic
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Set the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param extensionData to set the extension
     */
    function setExtension(bytes calldata extensionData)
        public
        virtual
        nonReentrant
    {
        (address[] memory tokens, uint256 withdrawalStart) =
            abi.decode(extensionData, (address[], uint256));

        if (tokens.length == 0) revert NullTokens();

        // If withdrawables are already set, this call will be interpreted as reset
        if (withdrawables[msg.sender].length != 0)
        delete withdrawables[msg.sender];
        // Cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                withdrawables[msg.sender].push(tokens[i]);
            }
        }

        withdrawalStarts[msg.sender] = withdrawalStart;

        emit ExtensionSet(msg.sender, tokens, withdrawalStart);
    }

    /**
     * @notice Withdraw tokens from a DAO. This will withdraw tokens in proportion to the amount of DAO tokens burned.
     * @param withdrawer address to withdraw tokens to
     * @param amount amount of DAO tokens burned
     * @dev bytes unused but conforms with standard interface for extension
     */
    function callExtension(address withdrawer, uint256 amount, bytes calldata)
        public
        virtual
        nonReentrant
        returns (bool mint, uint256 amountOut)
    {
        if (block.timestamp < withdrawalStarts[msg.sender]) revert NotStarted();

        for (uint256 i; i < withdrawables[msg.sender].length;) {
            // Calculate fair share of given token for withdrawal
            uint256 amountToRedeem = amount
                * IERC20(withdrawables[msg.sender][i]).balanceOf(msg.sender)
                / IERC20(msg.sender).totalSupply();

            // `transferFrom` DAO to redeemer
            if (amountToRedeem != 0) {
                address(withdrawables[msg.sender][i])._safeTransferFrom(
                    msg.sender, withdrawer, amountToRedeem
                );
            }

            // cannot realistically overflow on human timescales
            unchecked {
                i++;
            }
        }

        // Values to conform to extension interface and burn group tokens of this amount
        (mint, amountOut) = (false, amount);

        emit ExtensionCalled(msg.sender, withdrawer, amount);
    }

    /**
     * @notice Submits a proposal to the group to withdraw an item not already set in the extension.
     * @param group to withdraw from
     * @param accounts contract address of assets to withdraw
     * @param amounts to withdraw if needed
     */
    function submitWithdrawlProposal(
        IForumGroup group,
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 amount
    )
        public
        payable
        virtual
        nonReentrant
    {
        // Sender must be group member
        if (group.balanceOf(msg.sender, 0) == 0) revert NotMember();

        // Array lenghts must match
        if (accounts.length != amounts.length) revert NoArrayParity();

        // Set allowance for DAO to burn members tokens
        customWithdrawals[address(group)][msg.sender].amountToBurn += amount;

        // +1 to include the call to processWithdrawalProposal function on this contract
        uint256 adjustedArrayLength = accounts.length + 1;

        // Accouts to be sent to the group proposal
        address[] memory proposalAccounts = new address[](adjustedArrayLength);

        for (uint256 i; i < accounts.length;) {
            proposalAccounts[i] = accounts[i];

            // Will not overflow for length of assets
            unchecked {
                ++i;
            }
        }

        // Add this contract to the end of the array
        proposalAccounts[adjustedArrayLength - 1] = address(this);

        // Create payloads based on input tokens and amounts
        bytes[] memory proposalPayloads = new bytes[](adjustedArrayLength);

        // Loop the input accounts and create payloads
        for (uint256 i; i < accounts.length;) {
            // Build the approval for the group to allow the asset to be transferred
            proposalPayloads[i] = withdrawalTransferManager
                .buildApprovalPayloads(accounts[i], amounts[i]);

            // Store the account and amountOrId which can be withdrawn from it
            // This ensures that only this member from this group can withdraw the assets the group have approved
            customWithdrawals[address(group)][msg.sender].tokens.push(
                accounts[i]
            );
            customWithdrawals[address(group)][msg.sender].amountOrId.push(
                amounts[i]
            );

            // Will not overflow for length of assets
            unchecked {
                ++i;
            }
        }

        // Build the payload to call processWithdrawalProposal on this contract and put it as the last payload
        // This will process the withdrawal as soon as the vote is passed
        proposalPayloads[adjustedArrayLength - 1] = abi.encodeWithSignature(
            "processWithdrawalProposal(address)", msg.sender
        );

        // Submit proposal to DAO - amounts is set to an new empty array as it is not needed (amounts are set in the payloads)
        uint256 proposal = group.propose(
            IForumGroupTypes.ProposalType.CALL,
            proposalAccounts,
            new uint256[](adjustedArrayLength),
            proposalPayloads
        );

        emit CustomWithdrawalAdded(msg.sender, address(group), proposal, amount);
    }

    /**
     * @notice processWithdrawalProposal processes a proposal to withdraw an item not already set in the extension.
     * @param withdrawer to take assets and burn tokens for
     */
    function processWithdrawalProposal(address withdrawer)
        public
        virtual
        nonReentrant
    {
        CustomWithdrawal memory withdrawal =
            customWithdrawals[msg.sender][withdrawer];

        // Burn group tokens (id=1)
        IForumGroup(msg.sender).burnShares(
            withdrawer, 1, withdrawal.amountToBurn
        );

        for (uint256 i; i < withdrawal.tokens.length;) {
            // For each token, transfer the amountOrId to the withdrawer
            withdrawalTransferManager.executeTransferPayloads(
                withdrawal.tokens[i],
                msg.sender,
                withdrawer,
                withdrawal.amountOrId[i]
            );

            // Will not overflow for length of assets
            unchecked {
                ++i;
            }
        }

        emit CustomWithdrawalProcessed(
            msg.sender, msg.sender, withdrawal.amountToBurn
            );

        // Delete the withdrawal
        delete customWithdrawals[msg.sender][withdrawer];
    }

    /**
     * @notice lets a member remove their custom withdrawal request
     * @param group to remove allowance from
     */
    function removeAllowance(address group) public virtual nonReentrant {
        delete customWithdrawals[group][msg.sender];
    }

    /**
     * @notice Add tokens to the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param tokens to add to the withdrawl extension
     */
    function addTokens(address[] calldata tokens) public virtual nonReentrant {
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                withdrawables[msg.sender].push(tokens[i]);
            }
        }

        emit TokensAdded(msg.sender, tokens);
    }

    /**
     * @notice Remove tokens from the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param tokenIndex to remove from the withdrawl extension
     */
    function removeTokens(uint256[] calldata tokenIndex)
        public
        virtual
        nonReentrant
    {
        for (uint256 i; i < tokenIndex.length; i++) {
            // move last token to replace indexed spot and pop array to remove last token
            withdrawables[msg.sender][tokenIndex[i]] =
                withdrawables[msg.sender][withdrawables[msg.sender].length - 1];

            withdrawables[msg.sender].pop();
        }

        emit TokensRemoved(msg.sender, tokenIndex);
    }

    function getWithdrawables(address group)
        public
        view
        virtual
        returns (address[] memory tokens)
    {
        tokens = withdrawables[group];
    }

    /**
     * @notice Returns the custom withdrawal for a member of a group
     * @param group to get custom withdrawal from
     * @param member to get custom withdrawal for
     */
    function getCustomWithdrawals(address group, address member)
        public
        view
        virtual
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256 amountToBurn
        )
    {
        tokens = customWithdrawals[group][member].tokens;
        amounts = customWithdrawals[group][member].amountOrId;
        amountToBurn = customWithdrawals[group][member].amountToBurn;
    }
}