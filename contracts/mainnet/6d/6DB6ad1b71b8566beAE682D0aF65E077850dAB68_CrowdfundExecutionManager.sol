// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {Owned} from "../../utils/Owned.sol";

import {ICrowdfundExecutionHandler} from
    "../../interfaces/ICrowdfundExecutionHandler.sol";
import {ICrowdfundExecutionManager} from
    "../../interfaces/ICrowdfundExecutionManager.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

/**
 * @title CrowdfundExecutionManager
 * @notice It allows adding/removing executionHandlers to manage crowdfund executions.
 * @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)
 */
contract CrowdfundExecutionManager is ICrowdfundExecutionManager, Owned {
    /// ----------------------------------------------------------------------------------------
    ///							ERRORS & EVENTS
    /// ----------------------------------------------------------------------------------------

    error UnsupportedTarget();

    error TransferFailed();

    event ExecutionHandlerUpdated(
        address indexed handledAddress, address indexed newExecutionHandler
    );

    event ExecutionHandlerAdded(
        address indexed newHandledAddress, address indexed executionHandler
    );

    /// ----------------------------------------------------------------------------------------
    ///							ExecutionManager Storage
    /// ----------------------------------------------------------------------------------------

    /// @notice Each executionHandler is an address with logic to extract the details of the execution, for example asset price, contract address, etc.
    mapping(address => address) public executionHandlers;

    /// ----------------------------------------------------------------------------------------
    ///							Constructor
    /// ----------------------------------------------------------------------------------------

    constructor(address deployer) Owned(deployer) {}

    /// ----------------------------------------------------------------------------------------
    ///							Owner Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Add a executionHandler
     * @param newHandledAddress address of contract to handle executions for
     * @param executionHandler address of the executionHandler
     */
    function addExecutionHandler(
        address newHandledAddress,
        address executionHandler
    )
        external
        onlyOwner
    {
        executionHandlers[newHandledAddress] = executionHandler;
        emit ExecutionHandlerAdded(newHandledAddress, executionHandler);
    }

    /**
     * @notice Update a executionHandler
     * @param handledAddress address of the contract which we handle executions for
     * @param newExecutionHandler address of the updated handler
     */
    function updateExecutionHandler(
        address handledAddress,
        address newExecutionHandler
    )
        external
        onlyOwner
    {
        executionHandlers[handledAddress] = newExecutionHandler;

        emit ExecutionHandlerUpdated(handledAddress, newExecutionHandler);
    }

    /**
     * @notice Collect native fees
     * @dev This is not onlyOwner to enable automation of the fee collection.
     */
    function collectFees() external {
        (bool success,) =
            payable(owner).call{value: address(this).balance}(new bytes(0));
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

    // ! consider more tidy way to get props into executionHandler
    /**
     * @notice Manage the routing to an executionHandler based on the contract
     * @param payload payload sent to contract which will be decoded
     * @param forumGroup contract address
     */
    function manageExecution(
        address crowdfundContract,
        address targetContract,
        address assetContract,
        address forumGroup,
        uint256 tokenId,
        bytes calldata payload
    )
        external
        view
        returns (uint256, bytes memory)
    {
        // If the target has a handler, use it
        if (executionHandlers[targetContract] != address(0)) return
        ICrowdfundExecutionHandler(executionHandlers[targetContract])
            .handleCrowdfundExecution(
            crowdfundContract, assetContract, forumGroup, tokenId, payload
        );

        revert UnsupportedTarget();
    }

    receive() external payable virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice ICrowdfundExecutionHandler interface.

interface ICrowdfundExecutionHandler {
	function handleCrowdfundExecution(
		address crowdfundContract,
		address assetContract,
		address forumGroup,
		uint256 tokenId,
		bytes calldata payload
	) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice Crowdfund Execution Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

interface ICrowdfundExecutionManager {
	function addExecutionHandler(address newHandledAddress, address handlerAddress) external;

	function updateExecutionHandler(address proposalHandler, address newProposalHandler) external;

	function manageExecution(
		address crowdfundContract,
		address targetContract,
		address assetContract,
		address forumGroup,
		uint256 tokenId,
		bytes memory payload
	) external returns (uint256, bytes memory);
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