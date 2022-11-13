// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {Owned} from "../utils/Owned.sol";
import {NFTreceiver} from "../utils/NFTreceiver.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

import {IForumGroup} from "../interfaces/IForumGroup.sol";
import {IForumGroupFactoryV2} from "../interfaces/IForumGroupFactoryV2.sol";
import {ICrowdfundExecutionManager} from
    "../interfaces/ICrowdfundExecutionManager.sol";

/**
 * @title Forum Crowdfund
 * @notice Lets people pool funds to purchase an item as a group, deploying a Forum group for management
 */
contract ForumCrowdfund is ReentrancyGuard, Owned, NFTreceiver {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event NewCrowdfund(string indexed groupName);

    event FundsAdded(
        string indexed groupName, address contributor, uint256 contribution
    );

    event CommissionSet(uint256 commission);

    event Cancelled(string indexed groupName);

    event Processed(string indexed groupName, address indexed groupAddress);

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error MissingCrowdfund();

    error MemberLimitReached();

    error InsufficientFunds();

    error FounderBonusExceeded();

    error OpenFund();

    /// -----------------------------------------------------------------------
    /// Crowdfund Storage
    /// -----------------------------------------------------------------------

    struct CrowdfundParameters {
        address targetContract; // When the crowdfund transaction will take place (eg. a marketplace)
        address assetContract; // The asset contract the crowdfund will buy (eg. an ERC721 collection)
        uint32 deadline; // The deadline for the crowdfund
        uint256 tokenId; // The token ID the crowdfund will buy
        uint256 founderBonus; // An optional bonus the founder can set to incentivize early contributions
        string groupName; // The name of the group which will be deployed to manage the groups asset
        string symbol; // The symbol of the group which will be deployed to manage the groups asset
        bytes payload; // The payload to be sent to the target contract when the crowdfund is processed
    }

    struct Crowdfund {
        address[] contributors;
        mapping(address => uint256) contributions;
        CrowdfundParameters parameters;
    }

    address public forumFactory;
    address public executionManager;

    uint256 public commission = 250; // Basis points of 10000 => 2.5%

    mapping(bytes32 => Crowdfund) private crowdfunds;

    mapping(address => mapping(address => bool)) public contributionTracker;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        address deployer,
        address forumFactory_,
        address executionManager_
    )
        Owned(deployer)
    {
        forumFactory = forumFactory_;

        executionManager = executionManager_;
    }

    /// ----------------------------------------------------------------------------------------
    ///							Owner Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Sets commission %
     * @param _commission for crowdfunds as basis points on 1000 (e.g. 250 = 2.5%)
     */
    function setCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
        emit CommissionSet(_commission);
    }

    /// -----------------------------------------------------------------------
    /// Fundraise Logic
    /// -----------------------------------------------------------------------

    /**
     * @notice Initiate a crowdfund to buy an asset
     * @param parameters the parameters struct for the crowdfund
     */
    function initiateCrowdfund(CrowdfundParameters calldata parameters)
        public
        payable
        virtual
        nonReentrant
    {
        // Using the bytes32 hash of the name as mapping key saves ~250 gas instead of string
        bytes32 groupNameHash = keccak256(abi.encode(parameters.groupName));

        if (crowdfunds[groupNameHash].parameters.deadline != 0) revert OpenFund();

        // Founder bonus capped at 5%
        if (parameters.founderBonus > 500) revert FounderBonusExceeded();

        // No gas saving to use crowdfund({}) format, and since we need to push to the array, we assign each element individually.
        crowdfunds[groupNameHash].parameters = parameters;
        crowdfunds[groupNameHash].contributors.push(msg.sender);
        crowdfunds[groupNameHash].contributions[msg.sender] = msg.value;

        emit NewCrowdfund(parameters.groupName);
    }

    /**
     * @notice Submit a crowdfund contribution
     * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
     */
    function submitContribution(bytes32 groupNameHash)
        public
        payable
        virtual
        nonReentrant
    {
        Crowdfund storage fund = crowdfunds[groupNameHash];

        if (fund.parameters.deadline == 0) revert MissingCrowdfund();

        if (fund.contributors.length == 100) revert MemberLimitReached();

        if (fund.contributions[msg.sender] == 0) {
            fund.contributors.push(msg.sender);
            fund.contributions[msg.sender] = msg.value;
        } else crowdfunds[groupNameHash].contributions[msg.sender] += msg.value;

        emit FundsAdded(fund.parameters.groupName, msg.sender, msg.value);
    }

    /**
     * @notice Cancel a crowdfund and return funds to contributors
     * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
     */
    function cancelCrowdfund(bytes32 groupNameHash)
        public
        virtual
        nonReentrant
    {
        Crowdfund storage fund = crowdfunds[groupNameHash];

        if (fund.parameters.deadline > block.timestamp) revert OpenFund();

        // Return funds from escrow
        for (uint256 i; i < fund.contributors.length;) {
            payable(fund.contributors[i]).call{
                value: fund.contributions[msg.sender]
            }("");

            // Delete the contribution in the mapping
            delete fund.contributions[fund.contributors[i]];

            // Members can only be 12
            unchecked {
                ++i;
            }
        }

        delete crowdfunds[groupNameHash];

        emit Cancelled(fund.parameters.groupName);
    }

    /**
     * @notice Process a crowdfund and deploy a Forum group
     * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
     */
    function processCrowdfund(bytes32 groupNameHash)
        public
        virtual
        nonReentrant
    {
        Crowdfund storage fund = crowdfunds[groupNameHash];

        if (fund.parameters.deadline == 0) revert MissingCrowdfund();

        // CustomExtension of address(this) allows this contract to mint each member shares
        address[] memory customExtensions = new address[](1);
        customExtensions[0] = address(this);

        // Deploy the Forum group to hold the NFT as a group
        // Default settings of 3 days vote period, 100 member limit, 80% member & token vote thresholds
        IForumGroup forumGroup = IForumGroupFactoryV2(forumFactory).deployGroup(
            fund.parameters.groupName,
            fund.parameters.symbol,
            fund.contributors,
            [uint32(3 days), uint32(100), uint32(80), uint32(80)],
            customExtensions
        );

        // Decode the executed payload based on the target contract,
        // and generate a transferPayload to send the asset to the Forum group after it is purchased
        (uint256 assetPrice, bytes memory transferPayload) =
        ICrowdfundExecutionManager(executionManager).manageExecution(
            address(this),
            fund.parameters.targetContract,
            fund.parameters.assetContract,
            address(forumGroup),
            fund.parameters.tokenId,
            fund.parameters.payload
        );

        // Total raised and expected commission
        uint256 raised;
        uint256 expectedCommmission = (assetPrice * commission) / 10000;

        // Unchecked as price or raised amount will not exceed max int
        unchecked {
            // Calculate the total raised and mint group shares (id = 1) to each contributor
            for (uint256 i; i < fund.contributors.length;) {
                raised += fund.contributions[fund.contributors[i]];
                forumGroup.mintShares(
                    fund.contributors[i],
                    1,
                    fund.contributions[fund.contributors[i]]
                );
                ++i;
            }
            if (raised == 0 || raised < expectedCommmission) revert
                InsufficientFunds();
        }

        // Send the founder bonus
        forumGroup.mintShares(
            fund.contributors[0],
            1,
            (raised * fund.parameters.founderBonus) / 10000
        );

        // Execute the tx with payload
        (bool success, bytes memory result) = (fund.parameters.targetContract)
            .call{value: assetPrice}(fund.parameters.payload);

        // If the tx fails, revert
        if (!success) revert(string(result));

        // Send the asset to the Forum group
        (bool success2,) = (fund.parameters.assetContract).call(transferPayload);

        // If the transfer fails, revert
        if (!success2) revert(string(result));

        // Excess funds to pay commission and be transferred to group
        uint256 excessFunds = raised - assetPrice;
        uint256 finalCommission = (raised * commission) / 10000;

        // Revert if insufficent funds to pay commission, otherwise send commission to Forum.
        if (excessFunds < expectedCommmission) revert InsufficientFunds();
        executionManager.call{value: finalCommission}(new bytes(0));

        // Update the value of the excess funds after commission has been taken
        excessFunds -= finalCommission;

        // If there are leftover funds, transfer them to the forum group
        if (excessFunds > 0) {
            address(forumGroup).call{value: excessFunds}("");
        }

        emit Processed(fund.parameters.groupName, address(forumGroup));

        delete crowdfunds[groupNameHash];
    }

    /**
     * @notice Get the details of a crowdfund
     * @param groupNameHash hash of the group name
     */
    function getCrowdfund(bytes32 groupNameHash)
        public
        view
        returns (
            CrowdfundParameters memory details,
            address[] memory contributors,
            uint256[] memory contributions
        )
    {
        Crowdfund storage fund = crowdfunds[groupNameHash];

        contributions =
            new uint256[](crowdfunds[groupNameHash].contributors.length);
        for (uint256 i; i < fund.contributors.length;) {
            contributions[i] = fund.contributions[fund.contributors[i]];
            unchecked {
                ++i;
            }
        }
        (details, contributors, contributions) =
            (fund.parameters, fund.contributors, contributions);
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice ForumGroup interface
interface IForumGroup {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {IForumGroup} from './IForumGroup.sol';

/// @notice Forum Factory V2 Interface.
interface IForumGroupFactoryV2 {
	function deployGroup(
		string calldata name_,
		string calldata symbol_,
		address[] calldata voters_,
		uint32[4] calldata govSettings_,
		address[] calldata customExtensions_
	) external payable returns (IForumGroup);
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