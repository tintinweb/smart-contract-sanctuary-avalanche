// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IRarity.sol";
import "../interfaces/IrERC20.sol";
import "../interfaces/IRarityCooking.sol";

contract rarity_extended_cooking_helper {
    string constant public name = "Rarity Extended Cooking Helper";

    // Define the list of addresse we will need to interact with
    IRarity public _rm;
    IrERC20 public _rarityGold;
    IRarityCooking public _rarityCooking;
    uint immutable RARITY_COOKING_SUMMMONER_ID; //NPC of the RarityCooking contract

    constructor(address _rmAddr, address _gold, address _rarityCookingAddress) {
        _rm = IRarity(_rm);
        _rarityGold = IrERC20(_gold);
        _rarityCooking = IRarityCooking(_rarityCookingAddress);
        RARITY_COOKING_SUMMMONER_ID = _rarityCooking.summonerCook();
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
    function cook(address _meal, uint _adventurer, uint _receiver) external {
        require(_isApprovedOrOwner(_adventurer), "!owner");

        // Allow this contract to craft for the adventurer
        _isApprovedOrApprove(_adventurer, address(this));

        (,,address[] memory ingredients, uint[] memory quantities) = _rarityCooking.getRecipe(_meal);

        for (uint i = 0; i < ingredients.length; i++) {
            IrERC20(ingredients[i]).approve(_adventurer, RARITY_COOKING_SUMMMONER_ID, quantities[i]);
        }
        
        _rarityCooking.cook(_meal, _adventurer, _receiver);
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

interface IRarityCooking {
    struct Recipe {
        bool isPaused;
        string name;
        string effect;
        address[] ingredients;
        uint[] quantities;
    }
    function summonerCook() external view returns (uint);
    function getRecipe(address meal) external view returns (string memory, string memory, address[] memory, uint[] memory);
    function cook(address mealAddr, uint chef, uint receiver) external;
    function recipes(address) external view returns (Recipe memory);
    function recipesByIndex(uint) external view returns (Recipe memory);
    function getRecipeByMealName(string memory name) external view returns (Recipe memory);
    function getMealAddressByMealName(string memory name) external view returns (address);
}