// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../interfaces/OnlyExtended.sol";
import "../interfaces/RarityExtended.sol";
import "../interfaces/IRarity.sol";
import "../interfaces/IRarityFarmBase.sol";

contract rarity_extended_farming_core is OnlyExtended, RarityExtended {
	string constant public NAME  = "Rarity Extended Farming Core";
	uint constant public XP_PER_HARVEST = 250;

	constructor() RarityExtended(false) {}

	/*******************************************************************************
	**  @dev Structure to hold the farm. There is two informations:
	**  - typeOf, aka type of farm (1 for wood, 2 minerals, etc.)
	**	- tier, aka level of the farm, rarity tier.
	*******************************************************************************/
	struct Farm {
		uint typeOf;
		uint tier;
	}

	mapping(address => Farm) public farm; //farm contract -> farmingType
	mapping(uint => mapping(uint => uint)) public level; //adventurer -> farmingType -> level
	mapping(uint => mapping(uint => uint)) public xp; //adventurer -> farmingType -> xp

	/*******************************************************************************
	**  @dev Assign a new farm contract to a farm index. As time of deployment
	**  slots are: 0 -> undefined, 1 -> Wood, 2 -> Mining.
	**	Any number of farm can be added, but a whitelisting is used to try to avoid
	**	breaking the unbalanced balance. (we are trying to balance if, not easy).
	**	@param _farm: Address of the farm contract
	*******************************************************************************/
	function registerFarm(address _farm) public onlyExtended() {
		require(_farm != address(0), "!address");
		uint8 farmType = IRarityFarmBase(_farm).typeOf();
		uint8 farmRequiredLevel = IRarityFarmBase(_farm).requiredLevel();
		require(farmType != 0, "!farm");
		require(farm[_farm].typeOf == 0, '!new');
		farm[_farm] = Farm(farmType, farmRequiredLevel);
	}

	/*******************************************************************************
	**  @dev Revoke an existing farm 
	**	@param _farm: Address of the farm contract
	*******************************************************************************/
	function revokeFarm(address _farm) public onlyExtended() {
		require(farm[_farm].typeOf != 0, '!exist');
		farm[_farm] = Farm(0, 0);
	}

	/*******************************************************************************
	**  @dev Give some XP to the _adventurer. Only a registered farm can do that.
	**	The amount of XP earned is computed based on the level of the adventurer and
	**	the level of the harvest he is using.
	**	The XP is shared for all the farm with the same typeOf.
	**	@param _adventurer: adventurer to give some XP
	*******************************************************************************/
	function earnXp(uint _adventurer) public returns (uint) {
		Farm memory _farm = farm[msg.sender];
		require(_farm.typeOf != 0, "!farm");
		uint256 xpProgress = XP_PER_HARVEST - (XP_PER_HARVEST * (level[_adventurer][_farm.typeOf] - _farm.tier) * 20e8 / 100e8);
		xp[_adventurer][_farm.typeOf] += xpProgress;
		return xp[_adventurer][_farm.typeOf];
	}

	/*******************************************************************************
	**  @dev Trigger a level-up for an adventurer if enough XP is available. This
	**	will increase the loot and unlock new farms.
	**	@param _adventurer: adventurer to level-up
	**	@param _farmType: type of farm to level-up the adventurer for
	*******************************************************************************/
	function levelup(uint _adventurer, uint _farmType) external returns (uint) {
		require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
		uint currentLevel = level[_adventurer][_farmType];
		uint currentXP = xp[_adventurer][_farmType];
		uint requiredXP = xpRequired(currentLevel + 1);
		require(currentXP >= requiredXP, "!xp");
		
		level[_adventurer][_farmType] += 1;
		xp[_adventurer][_farmType] -= requiredXP;
		return level[_adventurer][_farmType];
	}

	/*******************************************************************************
	**  @dev Compute the XP required for the next level for a given level
	**	@param _currentLevel: current level to work with
	*******************************************************************************/
	function xpRequired(uint _currentLevel) public pure returns (uint) {
		return (_currentLevel * (_currentLevel + 1) / 2) * 1000;
	}

	/*******************************************************************************
	**  @dev For a specific adventurer and farm, return it's current status.
	**	@param _currentLevel: current level to work with
	**	@param _farmType: type of farm to work with
	*******************************************************************************/
	function adventurerStatus(uint _adventurer, uint _farmType) public view returns (uint, uint) {
		return (level[_adventurer][_farmType], xp[_adventurer][_farmType]);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract OnlyExtended {
    address public extended;
    address public pendingExtended;

    constructor() {
        extended = msg.sender;
    }

    modifier onlyExtended() {
        require(msg.sender == extended, "!owner");
        _;
    }
    modifier onlyPendingExtended() {
		require(msg.sender == pendingExtended, "!authorized");
		_;
	}

    /*******************************************************************************
	**	@notice
	**		Nominate a new address to use as Extended.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the management address is not updated until
	**		the proposed Extended address has accepted the responsibility.
	**		This may only be called by the current Extended address.
	**	@param _extended The address requested to take over the role.
	*******************************************************************************/
    function setExtended(address _extended) public onlyExtended() {
		pendingExtended = _extended;
	}


	/*******************************************************************************
	**	@notice
	**		Once a new extended address has been proposed using setExtended(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over the role for this contract.
	**		This may only be called by the proposed Extended address.
	**	@dev
	**		setExtended() should be called by the existing extended address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptExtended() public onlyPendingExtended() {
		extended = msg.sender;
	}
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IRarity.sol";
import "./IERC721.sol";
import "./IrERC721.sol";
import "./IRandomCodex.sol";

abstract contract RarityExtended {
    IRarity constant _rm = IRarity(0x4Bf29564F5E0297386799C2F26Be4a537e2cE66a);
    IRandomCodex constant _random = IRandomCodex(0x928F50120caa647927937b3e077A787BC36eCB07);

	uint public RARITY_EXTENDED_NPC;

	constructor(bool requireSummoner) {
		if (requireSummoner) {
        	RARITY_EXTENDED_NPC = IRarity(_rm).next_summoner();
        	IRarity(_rm).summon(8);
		}
	}

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwner(uint _adventurer, address _operator) internal view returns (bool) {
        return (
			_rm.getApproved(_adventurer) == _operator ||
			_rm.ownerOf(_adventurer) == _operator ||
			_rm.isApprovedForAll(_rm.ownerOf(_adventurer), _operator)
		);
    }

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this tokenID
    **	@param _tokenID: TokenID of the item we want to check
    **	@param _source: address of contract for tokenID 
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwnerOfItem(uint _tokenID, IERC721 _source, address _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_source.ownerOf(_tokenID), _operator)
        );
    }
    function _isApprovedOrOwnerOfItem(uint256 _tokenID, IrERC721 _source, uint _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_tokenID, _operator)
        );
    }

}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.7;

interface IRarity {
    // ERC721
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    // Rarity
    event summoned(address indexed owner, uint256 _class, uint256 summoner);
    event leveled(address indexed owner, uint256 level, uint256 summoner);

    function next_summoner() external returns (uint256);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function xp(uint256) external view returns (uint256);

    function adventurers_log(uint256) external view returns (uint256);

    function class(uint256) external view returns (uint256);

    function level(uint256) external view returns (uint256);

    function adventure(uint256 _summoner) external;

    function spend_xp(uint256 _summoner, uint256 _xp) external;

    function level_up(uint256 _summoner) external;

    function summoner(uint256 _summoner)
        external
        view
        returns (
            uint256 _xp,
            uint256 _log,
            uint256 _class,
            uint256 _level
        );

    function summon(uint256 _class) external;

    function xp_required(uint256 curent_level)
        external
        pure
        returns (uint256 xp_to_next_level);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function classes(uint256 id)
        external
        pure
        returns (string memory description);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRarityFarmBase {
    function typeOf() external view returns (uint8);
    function requiredLevel() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    event Transfer(uint indexed from, uint indexed to, uint256 indexed tokenId);
    event Approval(uint indexed owner, uint indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(uint indexed owner, uint indexed operator, bool approved);
    function balanceOf(uint owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IrERC721 {
    function ownerOf(uint256 tokenId) external view returns (uint);
    function approve(uint from, uint to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (uint);
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
    function transferFrom(uint operator, uint from, uint to, uint256 tokenId) external;
    function permit(
        uint operator,
        uint from,
		uint to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external;
    function nonces(uint owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function mint(uint to) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}