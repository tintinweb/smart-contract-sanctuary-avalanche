// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Pausable.sol";
import "./ICharacters.sol";
import "./IRandom.sol";
import "./IRouble.sol";

pragma solidity ^0.8.13;

contract Adventure is Ownable, Pausable {

    //NOTE ⋯ Less notes in this smart contract because I lost half the files and had to rewrite them all over again from my memory.

    // SECTION STRUCTS _________________________________________________________________________________________________

        //NOTE Rarity multiplier will be inside perksTraits to avoid creating a new struct


    //ROLE ⋯ This struct ⤵ contains all the information about each multiplier per class
    struct perksTraits {
        uint perkReward;
        uint perkRate;
        uint perkFail;
        uint perkTime;
        uint perkMint;

        //NOTE ➡️ TOTAL = 4 bytes
    }

    //ROLE ⋯ This struct ⤵ contains all the information about a nft being used to play in adventure.sol
    struct playerTraits {
        bool   inAdventure;   
        uint8  mapId;
        uint8  seedId;
        uint32 timeleft;

        //NOTE ➡️ TOTAL = 5 bytes
    }

    //ROLE ⋯ This struct ⤵ contains all the information about a mapTraits
    struct mapTraits {
        bool   playable;        // ➡️ Playable or not
        bool   payment;         // ➡️ If false, pay with $SCRAP, else pay with $AVAX 
        uint8  entryPrize;      // ➡️ Prize to pay to enter                              Example (10000 $SCRAP/0.2 $AVAX)
        uint8  baseReward;      // ➡️ How much reward rewards does it return             Example (4000 $SCRAP)
        uint8  rewardRate;      // ➡️ Chances of returning something                     Example (40% chances of returning)
        uint8  failRate;        // ➡️ Reward rate in case he fails to return something   Example (baseReward x failedRate)
        uint8  mintRate;        // ➡️ Chances of returning with an rare adventurer       Example (0.3% chances of finding)
        uint8  maxTokens;       // ➡️ How many adventurers can be sent per owner         Example (3 adventurers per mapTraits)
        uint16 experience;  
        uint32 time;            // ➡️ How long will it take an adventurer to return      Example (3 Hours)

        //NOTE ➡️ TOTAL = 16 bytes, half a uint256
    }

    //!SECTION STRUCTS -------------------------------------------------------------------------------------------------

    // SECTION VARIABLES _______________________________________________________________________________________________

    uint8  totalMaps; 
    uint8  entryFee;
    // ↪ Uint8 counting the amount of maps we created so far
    uint16 maxJugger = 300;
    uint16 maxNinjas = 300;
    // ↪ How many special characters can we mint?

    //!SECTION VARIABLES -----------------------------------------------------------------------------------------------

    // SECTION MAPPINGS  _______________________________________________________________________________________________

    mapping (uint8  => perksTraits)   public perksData;
    // ↪ Mapping returning the perks of a class.

    mapping (uint8  => mapTraits)    public mapData;
    // ↪ Mapping returning the data of a map.

    mapping (uint8 => uint8)         public rarityBonus;
    // ↪ Mapping returning the bonus multiplier per rarity.

    mapping (uint   => playerTraits) public playerData;
    // ↪ Mapping returning the data of a nft playing.

    mapping (
        address => mapping(uint8 => uint8)
            )                 public  tokensInMap;   
    // tokensInMap[msg.sender][mapID] returns ➡️ Number of tokens inside the mapTraits of id "mapID" of that address
    // ↪ Mapping returning ➡️ The amount of tokens inside a mapTraits per owner


    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------

    // SECTION EVENTS __________________________________________________________________________________________________

    event mapCreated            (address owner, uint8 mapId, mapTraits traits);                
    // ↪ Emits event alerting ➡️ A new mapTraits has been created with ID: "mapID"

    event mapModified           (address owner, uint mapId, mapTraits traits);
    // ↪ Emits event alerting ➡️ Owner has modified a mapTraits

    event perkModified          (address owner, uint perkId, perksTraits traits);
    // ↪ Emits event alerting ➡️ Owner has modified the perks of a class

    event adventurerSent        (address account, uint tokenId, uint8 _mapId);
    // ↪ Emits event alerting ➡️ Player sent to the adventure, to mapID

    event adventurerRetrieved    (address account, uint tokenId, uint8 _mapId, uint amount, bool won);
    // ↪ Emits event alerting ➡️ Player came back from his adventure, indicates if he won anything, and how much.

    event totalEarned            (address account, uint tokenAmount, uint amount);
    // ↪ Emits event alerting ➡️ How much someone earned with the retrieve function

    //!SECTION EVENTS --------------------------------------------------------------------------------------------------

    // SECTION REFERENCES ______________________________________________________________________________________________

    IRouble     public rouble;
    IRandom     public random;
    ICharacters public characters;

    //!SECTION REFERENCES ----------------------------------------------------------------------------------------------

    // SECTION CONSTRUCTOR _____________________________________________________________________________________________

    constructor(address _rouble, address _characters, address _random) {


        // REFERENCES ⋯ Interfaces from other smart contracts
        rouble      = IRouble      (_rouble);
        random      = IRandom      (_random);
        characters  = ICharacters  (_characters);

    }

    //!SECTION CONSTRUCTOR ---------------------------------------------------------------------------------------------

    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________


    function viewToken (uint tokenId)
    external 
    view 
    returns (playerTraits memory) {
        return playerData[tokenId];
    }

    function viewTokensPerMap (uint8 mapId)
    external 
    view 
    returns (uint) {
        return tokensInMap[msg.sender][mapId];
    }
    

    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------
    
    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    function adventure(
        uint8 mapId, 
        uint[] memory tokenArr
    ) 
    external 
    payable 
    whenNotPaused {

        uint toPay;

        for (uint8 i; i > tokenArr.length; i++) {

            uint256 tokenId = tokenArr[i];
            toPay += _doPay(mapId);

            require(characters.isBlacklisted(tokenId) == false, 
            "Your token is blacklisted");
            require(characters.ownerOf(tokenId) == msg.sender, 
            "You are not the owner of this token");
            require(!playerData[tokenId].inAdventure,
            "Your token is already in an adventure");
            require(  // Check that owner has less than the limit of tokens per map
                tokensInMap[_msgSender()][mapId] < mapData[mapId].maxTokens,
                "You can't send more tokens that the map accepts per owner"
             );

            _confirmAdventure(mapId, tokenId);
        }

        _enoughPayed(mapId, toPay);
    }

    function retrieve(uint[] memory tokenArr) 
    external 
    whenNotPaused {

        uint toPay;

        random.forceUpdate();

        for (uint i; i < tokenArr.length; i++) {

            uint tokenId = tokenArr[i];
            playerTraits storage token = playerData[tokenId];
            uint8 mapId   = token.mapId;

            require(token.inAdventure, 
            "Your token must be in an adventure first");
            require(block.timestamp >= token.timeleft,
            "Your token has not returned from his adventure yet");
            require(characters.ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token");

            token.inAdventure = false;

            uint seed    = random.aV_uniqueSeed(playerData[tokenId].seedId, tokenId);
            toPay += _manageRewards(tokenId, mapId, seed);

            if (mapData[mapId].mintRate != 0) {
                _luckyFella(seed, mapId, tokenId);
            }
        }


        emit totalEarned (msg.sender, tokenArr.length, toPay);
        rouble.mint(msg.sender, toPay);
    }

    
    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------

    // SECTION INTERNAL FUNCTIONS ______________________________________________________________________________________

    function _confirmAdventure (
        uint8 _mapId, 
        uint _tokenId
    ) 
    internal 
    {
        random.manageRequests(msg.sender, false, true, 0);
        
        playerTraits storage player = playerData[_tokenId];

        tokensInMap[msg.sender][_mapId]++; 
        player.inAdventure = true;
        player.mapId       = _mapId;
        player.seedId      = random.aV_totalSeeds();
        player.timeleft    = _setTime(_mapId, _tokenId);

        emit adventurerSent (msg.sender, _tokenId, _mapId);
    }


    function _manageRewards (uint _tokenId, uint8 _mapId, uint seed)
    private
    returns (uint) {

        uint8 tokenRarity = _whichRarity(_tokenId);
        uint8 tokenClass  = _whichClass (_tokenId);

        mapTraits    storage map    = mapData   [_mapId];
        perksTraits  storage bonus  = perksData [tokenClass];

        uint8 rariBonus   = rarityBonus[tokenRarity];

        bool foundReward = _foundReward(
            map.rewardRate, 
            bonus.perkRate, 
            rariBonus, 
            seed
        );

        
        uint owedReward = _calcRewards(
            foundReward, 
            map.baseReward, 
            bonus.perkReward, 
            rariBonus,
            bonus.perkFail
        );

        emit adventurerRetrieved (msg.sender, _tokenId, _mapId, owedReward, foundReward);

        return owedReward;
    }

    function _foundReward (
        uint _mapRate,
        uint _rateBonus, 
        uint _rariBonus, 
        uint _seed
        )
    private
    pure
    returns (bool) {
        
        uint winningChances =   _basisCalc(
                                    _mapRate,
                                    _applyRarity(
                                        _rateBonus,
                                        _rariBonus,
                                        false
                                    )
                                );
        
        if (winningChances < (_seed % 100)) {return true;}
        else                                {return false;}

    }

    function _calcRewards (
        bool _found,
        uint _baseReward,
        uint _rewardBonus,
        uint _rarityBonus,
        uint _failedBonus
    )
    private
    pure
    returns (uint) {

        //NOTE If token found a reward
        if (_found) {
            return 
                _basisCalc(
                    _baseReward,
                    _applyRarity(
                        _rewardBonus,
                        _rarityBonus,
                        false
                    )
                );
        }

        //NOTE ⋯ spoiler alert, he did not 
        else {
            return
                _basisCalc(
                    _baseReward,
                    _applyRarity(
                        _failedBonus,
                        _rarityBonus,
                        false
                    )
                );
        }

    }


    function _luckyFella(
        uint  _seed,
        uint8 _mapId,
        uint  _tokenId
    )
    private {

        _seed >>= 16;
        uint won = _basisCalc(
            mapData[_mapId].mintRate,
            _applyRarity(
                perksData[_whichClass(_tokenId)].perkMint, 
                rarityBonus[_whichRarity(_tokenId)],
                false
            )
        );

        if (won < _seed % 1000) {
            characters.specialMint(msg.sender, _seed);
        }
    }

    function _setTime (uint8 _mapId, uint _tokenId)
    private 
    view
    returns (uint32)
    {

        uint totalBonus = _applyRarity (
            perksData  [_whichClass (_tokenId)].perkTime,
            rarityBonus[_whichRarity(_tokenId)],
            true   
        );

        return uint32(_basisCalc(mapData[_mapId].time, totalBonus));

    }


    function _basisCalc(uint _amount, uint _basisPoints)
    private
    pure
    returns (uint) {

        return _amount * (_basisPoints * 100) / 10000;
    }


    function _applyRarity(uint _perkBonus, uint _rarBonus, bool time)
    internal
    pure
    returns (uint) {
        uint perkPercentage;

        if (_perkBonus >= 100) {perkPercentage = _perkBonus - 100;}
        else                  {perkPercentage = 100 - _perkBonus;}

        if (time) {
            return _perkBonus - _basisCalc(perkPercentage, _rarBonus);    
        }
        
        else {
            return _perkBonus + _basisCalc(perkPercentage, _rarBonus);
        }
        
    }

    function _doPay(uint8 _mapId) 
    private
    view 
    returns (uint)
    {
        mapTraits storage map = mapData[_mapId];

        if (map.entryPrize > 0) {
            if (map.payment) {
                return uint(map.entryPrize * 10**16);
            }
            else {
                return uint(map.entryPrize * 10**2);
            }
        } else {
            return 0;
        }
    }   

    function _enoughPayed(
        uint8 _mapId, 
        uint _amount
    ) 
    internal 
    {
        mapTraits storage map = mapData[_mapId];

        if (map.payment) {
            require(msg.value >= _amount,
                "It seems you haven't sent enough $AVAX");
        }
        else { // Payment in tokens
            require(rouble.balanceOf(msg.sender) >= _amount,
            "It seems you do not possess enough $ROUBLE to cover this transaction");
            rouble.burn(msg.sender, _amount);
        }
    }

    function _whichClass(uint _tokenId) 
    private 
    view 
    returns (uint8 class) 
    {
        (class, , , , , , ) = characters.getCharacter(_tokenId);
        return class;
    }

    function _whichRarity(uint _tokenId) 
    private 
    view 
    returns (uint8 rarity) 
    {
        ( , rarity, , , , , ) = characters.getCharacter(_tokenId);
        return rarity;
    }

    function _toPercentage(uint basisPoints, uint amount)
    private 
    pure
    returns (uint)
    {
        return (amount * basisPoints) / 10000;
    }
    //!SECTION INTERNAL FUNCTIONS --------------------------------------------------------------------------------------

    // SECTION ONLYOWNER FUNCTIONS _____________________________________________________________________________________

    function toolMap (
        bool    _create,        // Are we creating a new map or just modifying one?
        bool    _playable,      // Is this map playable?
        bool    _payment,       // Are we paying with $ROUBLE or $AVAX?
        uint8   _entryPrize,     // If this parameter > 0, we are paying, but how much?
        uint8   _baseReward,    // Whats the reward without perk or rarity multipliers amount?
        uint8   _rewardRate,    // Whats the chances for a player to find a reward?
        uint8   _failRate,      // If he doesnt get the reward how much will he still get rewarded?
        uint8   _mintRate,      // Does this map mint any new character?
        uint8   _maxTokens,     // How many tokens can a map hold?
        uint8   _mapId,         // If we are modifying a map, which map are we modifying?
        uint16  _experience,    // How many adventures does your account need to play this map?
        uint32  _time           // How long will my character take to come back? 

    ) external onlyOwner {

        mapTraits memory object = mapTraits(              // Create a copy of mapTraits struct to memory
            _playable,
            _payment,
            _entryPrize,
            _baseReward,
            _rewardRate,
            _failRate,
            _mintRate,
            _maxTokens,
            _experience,
            _time
        );

        mapData[totalMaps] = object;    // Store memory copy to storage with a mapping
        
        if (_create) { // NOTE IS THIS A NEW MAP?
            emit mapCreated(msg.sender, totalMaps, mapData[totalMaps]); // Alert ❗ ⋯ New map created
            totalMaps++;
        } else {
            emit mapModified(msg.sender, _mapId, mapData[_mapId]);      // Alert ❗ ⋯ Map modified
        }
    }

    function toolPerks (    

        // NOTE ⋯ We do not indicate if we are creating a new one since there is a fixed amount of perks

        uint8 _perkId,
        uint8 _perkReward,  // Reward multiplier
        uint8 _perkRate,    // Rate   multiplier
        uint8 _perkFail,    // Fail   multiplier
        uint8 _perkTime,    // Time   multiplier
        uint8 _perkMint     // Mint   multiplier

    ) external onlyOwner {

        perksTraits memory object = perksTraits(
            _perkReward,
            _perkRate,
            _perkFail,
            _perkTime,
            _perkMint
        );

        perksData[_perkId] = object;
        emit perkModified(msg.sender, _perkId, perksData[_perkId]);

    }

    function toolRarity (
        uint8 bonus,
        uint8 rarityId

    ) external onlyOwner 
    {rarityBonus[rarityId] = bonus;}

    //!SECTION ONLYOWNER FUNCTIONS -------------------------------------------------------------------------------------

}