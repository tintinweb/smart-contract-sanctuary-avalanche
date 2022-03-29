// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IRarity.sol";
import "../interfaces/IrERC20.sol";
import "../interfaces/IRarityCrafting.sol";

contract rarity_extended_crafting_helper is IERC721Receiver {
    string constant public name = "Rarity Extended Crafting Helper";

    // Define the list of addresse we will need to interact with
    IRarity public _rm;
    IrERC20 public _rarityCraftingMaterials;
    IrERC20 public _rarityGold;
    IRarityCrafting public _rarityCrafting;
    uint constant RARITY_CRAFTING_SUMMMONER_ID = 1758709; //NPC of the RarityCrafting contract

    struct Item {
        uint8 base_type;
        uint8 item_type;
        uint256 crafter;
        uint256 item_id;
    }

    mapping(uint => uint) public expected;
    constructor(address _rm_, address _rcrafting_materials, address _gold, address _rcrafting) {
        _rm = IRarity(_rm_);
        _rarityCraftingMaterials = IrERC20(_rcrafting_materials);
        _rarityGold = IrERC20(_gold);
        _rarityCrafting = IRarityCrafting(_rcrafting);
    }
    /**********************************************************************************************
    **  @dev The Craft function is inherited from the rarity_crafting contract. The idea is to
    **  provide a way to craft items without having to handle the approve parts. This contract will
    **  do a few manipulations to achieve this.
    **	@param _adventurer: TokenID of the adventurer to craft with
    **	@param _base_type: Category of the item to craft
    **	@param _item_type: Information about the item to craft
    **	@param _crafting_materials: Amount of crafting materials to use
    **********************************************************************************************/
    function craft(uint _adventurer, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external {
        (bool simulation,,,) = _rarityCrafting.simulate(_adventurer, _base_type, _item_type, _crafting_materials);
        require(simulation, "Simulation failed");
        require(_isApprovedOrOwner(_adventurer), "!owner");

        // Allow this contract to craft for the adventurer
        _isApprovedOrApprove(_adventurer, address(this));

        // Contract is doing the needed approves - Note: we could use the actual requirements
        _rarityGold.approve(_adventurer, RARITY_CRAFTING_SUMMMONER_ID, type(uint256).max);
        if (_crafting_materials > 0) {
            _rarityCraftingMaterials.approve(_adventurer, RARITY_CRAFTING_SUMMMONER_ID, type(uint256).max);
        }

        // If the craft succeeds, the NFT crafted should be the current `next_item`
        uint256 nextItem = _rarityCrafting.next_item();

        // As it's synchronous, we register that for this specific item, we expect _adventurer to be the owner
        expected[nextItem] = _adventurer;
        
        // We try to craft. On success, jump to `onERC721Received`
        _rarityCrafting.craft(_adventurer, _base_type, _item_type, _crafting_materials);
        expected[nextItem] = 0;

        // We can now check if the new current `next_item` is not the same as we expected.
        // If so, craft was successful and we can send the NFT to the actual owner
        uint256 newNextItem = _rarityCrafting.next_item();
        if (nextItem != newNextItem) {
            _rarityCrafting.transferFrom(address(this), msg.sender, nextItem);
        }
    }

    /**********************************************************************************************
    **  @dev The contract will receive the NFT from the rarity_crafting contract. Therefor, we need
    **  this function for the SafeMint to be successful. Moreover, because of the missing check on
    **  isApprovedForAll, there is a manipulation to allow the spending of the xp. Little hack.
    **	@param tokenId: ID of the ERC721 being received
    **********************************************************************************************/
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(_rarityCrafting), "!rarity_crafting");
        require(operator == address(this), "!operator");
        require(from == address(0), "!mint");
        _rm.approve(address(_rarityCrafting), expected[tokenId]);
        return this.onERC721Received.selector;
    }

    /**********************************************************************************************
    **  @dev Some helper function to retrieve, for a given addresses, all the ERC20 tokens
    **  availables with some relevant information.
    **	@param _owner: address of the owner
    **********************************************************************************************/
    function getItemsByAddress(address _owner) public view returns (Item[] memory) {
        require(_owner != address(0), "cannot retrieve zero address");
        uint256 arrayLength = _rarityCrafting.balanceOf(_owner);

        Item[] memory _items = new Item[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            uint256 tokenId = _rarityCrafting.tokenOfOwnerByIndex(_owner, i);
            (uint8 base_type, uint8 item_type,, uint256 crafter) = _rarityCrafting.items(tokenId);
            _items[i] = Item(base_type, item_type, crafter, tokenId);
        }
        return _items;
    }

    /**********************************************************************************************
    **  @dev Check if the msg.sender has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **********************************************************************************************/
    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return (
            _rm.getApproved(_summoner) == msg.sender ||
            _rm.ownerOf(_summoner) == msg.sender ||
            _rm.isApprovedForAll(_rm.ownerOf(_summoner), msg.sender)
        );
    }

    /**********************************************************************************************
    **  @dev Check if the summoner is approved for this contract as getApprovedForAll is
    **  not used for gold & cellar.
    **	@param _adventurer: TokenID of the adventurer we want to check
    **********************************************************************************************/
    function _isApprovedOrApprove(uint _adventurer, address _operator) internal {
        address _approved = _rm.getApproved(_adventurer);
        if (_approved != _operator) {
            _rm.approve(_operator, _adventurer);
        }
    }
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

interface IrERC20 {
    function burn(uint from, uint amount) external;
    function mint(uint to, uint amount) external;
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRarityCrafting {
    function craft(uint _adventurer, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function next_item() external view returns (uint);
    function SUMMMONER_ID() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function items(uint _id) external pure returns(
        uint8 base_type,
        uint8 item_type,
        uint32 crafted,
        uint256 crafter
    );
}