// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IRarity.sol";
import "../interfaces/IrERC20.sol";
import "../interfaces/IAttributes.sol";
import "../interfaces/IRandomCodex.sol";
import "../interfaces/onlyExtended.sol";


contract rarity_extended_spooky_festival is OnlyExtended {
    uint constant DAY = 1 days;
    string public constant name = "Rarity Extended Spooky Festival";
    string public constant symbol = "rSpook";
    uint256 public constant GIFT_CANDIES = 100;
    uint public immutable SUMMMONER_ID;
    uint public end_halloween_ts = 0;

    IRarity public _rm;
    IRandomCodex public _random;
    IAttributes public _attributes;
    IrERC20 public candies;

    mapping(uint => bool) public claimed;
    mapping(uint => uint) public trick_or_treat_count;
    mapping(uint => uint) public trick_or_treat_log;
    mapping(uint => uint) public activities_count;
    mapping(uint => uint) public activities_log;

    constructor(address _rm_, address _random_, address _attr, address _candiesAddr) OnlyExtended() {
        _rm = IRarity(_rm_);
        _random = IRandomCodex(_random_);
        _attributes = IAttributes(_attr);
        candies = IrERC20(_candiesAddr);
        SUMMMONER_ID = _rm.next_summoner();
        _rm.summon(11);
        end_halloween_ts = block.timestamp + (7 * DAY);
    }

    modifier can_do_activities(uint _summoner) {
        require(_isApprovedOrOwner(_summoner), "!owner");
        require(block.timestamp > activities_log[_summoner], "!activities");
    
        activities_count[_summoner] += 1;
        if (activities_count[_summoner] == 2) {
            //Two activities per day
            activities_log[_summoner] = block.timestamp + DAY;
            activities_count[_summoner] = 0;
        }
        _;
    }

    modifier is_halloween() {
        require(block.timestamp < end_halloween_ts, "!halloween");
        _;
    }

    function claim(uint _summoner) external is_halloween {
        require(_isApprovedOrOwner(_summoner), "!owner");
        require(claimed[_summoner] == false, "claimed");
        claimed[_summoner] = true;
        candies.mint(_summoner, GIFT_CANDIES);
    }

    function trick_or_treat(uint _summoner, uint256 _amount, uint _choice) external is_halloween {
        require(_isApprovedOrOwner(_summoner), "!owner");
        require(_amount == 25 || _amount == 50 || _amount == 100, "!invalidAmount");
        require(candies.transferFrom(SUMMMONER_ID, _summoner, SUMMMONER_ID, _amount), "!amount");
        require(block.timestamp > trick_or_treat_log[_summoner], "!action");
        require(_choice == 1 || _choice == 2 || _choice == 3, "!choice");
    
        trick_or_treat_count[_summoner] += 1;
        if (trick_or_treat_count[_summoner] == 3) {
           trick_or_treat_log[_summoner] = block.timestamp + DAY;
           trick_or_treat_count[_summoner] = 0;
        }

        uint random = _get_random(_summoner, 3, false);
        if (random == _choice) {
            candies.burn(SUMMMONER_ID, _amount);
            candies.mint(_summoner, _amount * 3);
        } else {
            candies.burn(SUMMMONER_ID, _amount);
        }
    }

    function throw_a_rock(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for strenght
        (uint str,,,,,) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, str);
    }

    function steal_a_pumpkin(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for dexterity
        (,uint dex,,,,) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, dex);
    }

    function tell_a_scary_story(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for charisma
        (,,,,,uint cha) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, cha);
    }

    function do_a_magic_trick(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for int
        (,,,uint inte,,) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, inte);
    }

    function cake_eating_contest(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for con
        (,,uint con,,,) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, con);
    }

    function do_some_babysitting(uint _summoner) external is_halloween can_do_activities(_summoner) {
        //Look for wisdom
        (,,,,uint wis,) = _attributes.ability_scores(_summoner);
        candies.mint(_summoner, wis);
    }

    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return (
            _rm.getApproved(_summoner) == msg.sender ||
            _rm.ownerOf(_summoner) == msg.sender ||
            _rm.isApprovedForAll(_rm.ownerOf(_summoner), msg.sender)
        );
    }

    function _get_random(uint _summoner, uint limit, bool withZero) public view returns (uint) {
        _summoner += gasleft();
        uint result = 0;
        if (withZero) {
            result = _random.dn(_summoner, limit);
        }else{
            if (limit == 1) {
                return 1;
            }
            result = _random.dn(_summoner, limit);
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarity {
    function adventure(uint _summoner) external;
    function xp(uint _summoner) external view returns (uint);
    function level_up(uint _summoner) external;
    function adventurers_log(uint adventurer) external view returns (uint);
    function approve(address to, uint256 tokenId) external;
    function level(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function classes(uint id) external pure returns (string memory);
    function summoner(uint _summoner) external view returns (uint _xp, uint _log, uint _class, uint _level);
    function spend_xp(uint _summoner, uint _xp) external;
    function next_summoner() external view returns (uint);
    function summon(uint _class) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IrERC20 {
    function burn(uint from, uint amount) external;
    function mint(uint to, uint amount) external;
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAttributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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