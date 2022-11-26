// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Owned} from '../utils/Owned.sol';

import {ICommissionManager} from '../interfaces/ICommissionManager.sol';
import {IProposalHandler} from '../interfaces/IProposalHandler.sol';
import {IERC20} from '../interfaces/IERC20.sol';

/**
 * @title CommissionManager
 * @notice It allows adding/removing proposalHandlers to collect commissions from proposals.
 * @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)
 */
contract CommissionManager is ICommissionManager, Owned {
	/// ----------------------------------------------------------------------------------------
	///							ERRORS & EVENTS
	/// ----------------------------------------------------------------------------------------

	error TransferFailed();

	event ProposalHandlerUpdated(
		address indexed handledAddress,
		address indexed newProposalHandler
	);

	event ProposalHandlerAdded(address indexed newHandledAddress, address indexed proposalHandler);

	/// ----------------------------------------------------------------------------------------
	///							CommissionManager Storage
	/// ----------------------------------------------------------------------------------------

	/// @notice Each proposalHandler is an address with logic to extract the details of the proposal to take commission fees from.
	mapping(address => address) public proposalHandlers;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) {}

	/// ----------------------------------------------------------------------------------------
	///							Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Add a proposalHandler
	 * @param newHandledAddress address of contract to handle proposals for
	 * @param proposalHandler address of the proposalHandler
	 */
	function addProposalHandler(
		address newHandledAddress,
		address proposalHandler
	) external onlyOwner {
		proposalHandlers[newHandledAddress] = proposalHandler;
		emit ProposalHandlerAdded(newHandledAddress, proposalHandler);
	}

	/**
	 * @notice Update a proposalHandler
	 * @param handledAddress address of the contract which we handle proposals for
	 * @param newProposalHandler address of the updated handler
	 */
	function updateProposalHandler(
		address handledAddress,
		address newProposalHandler
	) external onlyOwner {
		proposalHandlers[handledAddress] = newProposalHandler;

		emit ProposalHandlerUpdated(handledAddress, newProposalHandler);
	}

	/**
	 * @notice Collect native fees
	 * @dev This is not onlyOwner to enable automation of the fee collection.
	 */
	function collectFees() external {
		(bool success, ) = payable(owner).call{value: address(this).balance}(new bytes(0));
		if (!success) revert TransferFailed();
	}

	/**
	 * @notice Collect token fees
	 * @dev This is not onlyOwner to enable automation of the fee collection.
	 */
	function collectERC20(IERC20 erc20) external {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	/// ----------------------------------------------------------------------------------------
	///							Public Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Manage the routing to a proposalHandler based on the contract
	 * @param target target contract for proposal
	 * @param value value of tx
	 * @param payload payload sent to contract which will be decoded
	 */
	function manageCommission(
		address target,
		uint256 value,
		bytes memory payload
	) external view returns (uint256) {
		// If the target has a handler, use it
		if (proposalHandlers[target] != address(0))
			return IProposalHandler(proposalHandlers[target]).handleProposal(value, payload);
	}

	receive() external payable virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice Commission Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

interface ICommissionManager {
	function addProposalHandler(address newHandledAddress, address handlerAddress) external;

	function updateProposalHandler(address proposalHandler, address newProposalHandler) external;

	function manageCommission(
		address target,
		uint256 value,
		bytes memory payload
	) external returns (uint256);
}

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice ProposalHandler interface.

interface IProposalHandler {
	function handleProposal(uint256 value, bytes memory payload) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event OwnerUpdated(address indexed user, address indexed newOwner);

	/*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

	address public owner;

	modifier onlyOwner() virtual {
		require(msg.sender == owner, 'UNAUTHORIZED');

		_;
	}

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(address _owner) {
		owner = _owner;

		emit OwnerUpdated(address(0), _owner);
	}

	/*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

	function setOwner(address newOwner) public virtual onlyOwner {
		owner = newOwner;

		emit OwnerUpdated(msg.sender, newOwner);
	}
}