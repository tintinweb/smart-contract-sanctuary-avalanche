// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pauseable.sol";
import "./IERC721.sol";
import "./IPOT.sol";
import "./ICLOV.sol";
import "./ReentrancyGuard.sol";
import "./IGOLD.sol";


contract STAKINGBANK is Ownable, Pauseable, ReentrancyGuard {
    event POTStaked(address owner, uint256 tokenId, uint256 value);
    event CLOVStaked(address owner, uint256 tokenId, string rarity );
    event POTClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event CLOVClaimed(uint256 tokenId, bool unstaked, string rarity);
    event PotLost(uint256 tokenId, address previuosowner);
    
    
   

     /**
     * track of each pot details
     * @param tokenId  the ID of the POT
     * @param value    starting time of staking
     * @param owner    owner of the POT
     */
    struct StakePOT {
        uint256 tokenId;
        uint80 value;
        address owner;
    }
    // ownership of POT
    mapping(uint256 => address) public realOwnerOfPOT;

    // maps POT to stakePOT struct
    mapping(uint256 => StakePOT) public POTbank;

  
    /**
     * track of each CLOV details
     * @param tokenId  the ID of the Clov
     * @param owner    owner of the POT
     * @param rarity   type of clov
     */
    struct StakeCLOV {
        uint256 tokenId;
        address owner;
        string rarity;
    }
    // ownership of PCLOV
    mapping(uint256 => address) public realOwnerOfCLOV;

    // maps CLOV to stakeCLOV struct
    mapping(uint256 => StakeCLOV) public CLOVbank;

    /**
     * track of each staker details
     * @param owner    address of the staker
     * @param nPOT     number of staked pot
     * @param nCLOV    number of clov staked
     */
    struct Stakeinfo {
        address owner;
        uint256 nPOT;
        uint256 nCLOV;
        uint256 bonus;
    }
    // maps staker to stakeinfo struct
    mapping(address => Stakeinfo) public SInfo;


    // 0-19 POT earn 1 $GOLD per day
    uint256 public DAILY_LOOT_RATE_0_19 = 1 ether;
    // 20-39 POT earn 0.9 $GOLD per day
    uint256 public DAILY_LOOT_RATE_20_39 = 0.9 ether;
    // 40-59 POT earn 0.8 $GOLD per day
    uint256 public DAILY_LOOT_RATE_40_59 = 0.8 ether;
    // 60-79 POT earn 0.7 $GOLD per day
    uint256 public DAILY_LOOT_RATE_60_79 = 0.7 ether;
    // 80-100 POT earn 1 $GOLD per day
    uint256 public DAILY_LOOT_RATE_80_100 = 0.6 ether;
    // POT must have erned at least 7 gold to claim or the pot will be lost
    uint256 public MINIMUM_TO_CLAIM = 7 ether;
    uint256 public MAX_POT_STAKED = 100;
    uint256 public MAX_CLOVE_STAKED = 5;
    uint256 public Pbonus;
    uint256 public Gbonus;
    uint256 public Bbonus;
    uint256 public startTimestamp = 1644440400;
    uint256 previous = 1644440400;
    
    address public Treasury ;
    IERC721 public pot;
    ICLOV public cloves;
    IGOLD public gold;

    

    bool private _reentrant = false;
    bool public LosingPOTrisk = false;
    bool public canClaim = false;

    /***STAKING POT */

    /**
     * adds Gold Pot to the Bank 
     * @param account the address of the staker
     * @param tokenIds the IDs of the POT
     */
    function addManyPOTToBank(address account, uint16[] calldata tokenIds)
        public
        nonReentrant()
    {
        
        require((account == _msgSender() && account == tx.origin), "DONT GIVE YOUR TOKENS AWAY");
        require(!paused() || msg.sender == owner(), "Paused");
        Stakeinfo memory staker = SInfo[_msgSender()];
        require( (staker.nPOT + tokenIds.length)< MAX_POT_STAKED , "To many pot staked");
        IERC721 goldpot = pot;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }
            goldpot.setApprovalForAll(address(this), true);
            
            goldpot.transferFrom(_msgSender(), address(this), tokenIds[i]);

            _addPOTToBank(account, tokenIds[i]);

            realOwnerOfPOT[tokenIds[i]] = _msgSender();
        }
    }

    /**
     * adds a single POT to the Bank and update the Staker Info
     * @param account the address of the staker
     * @param tokenId the ID of the Thief to add to the Bank
     */
    function _addPOTToBank(address account, uint256 tokenId) internal {
        POTbank[tokenId] = StakePOT({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        Stakeinfo memory staker = SInfo[_msgSender()];
        staker.owner = _msgSender();
        staker.nPOT++;
        emit POTStaked(account, tokenId, block.timestamp);
    }

    /***CLAIMING / UNSTAKING */

    /**
     * Claming and unstaking od the eraned gold and the gold pot
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyPOTFromBank(uint16[] calldata tokenIds, bool unstake)
        external
        nonReentrant()
    {
        require(msg.sender == tx.origin, "Only EOA");
        require(canClaim || msg.sender == owner(), "Claim deactive");

        IGOLD Gold = gold;

        uint256 owed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint16 _id = tokenIds[i];

            owed += _claimPOTFromBank(_id, unstake);

            if (unstake) {
                require(owed >= MINIMUM_TO_CLAIM);
                realOwnerOfPOT[_id] = address(0);
            } else {
                realOwnerOfPOT[_id] = Treasury ;
            }
        }

        Gold.mint(_msgSender(), owed);
    }

    /**
     * Claiming and unstaking of Gold and Gold Pot
     * @param tokenId the ID of Pot to claiming ernings form
     * @param unstake whether or not to unstake the Pot
     * @return owed - the amount of $Gold earned
     */
    function _claimPOTFromBank(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {   
        IERC721 goldpot = pot;
        Stakeinfo memory staker = SInfo[_msgSender()];
        StakePOT memory stake = POTbank[tokenId];
        owed = getOwedAmount(tokenId);
        if(owed < MINIMUM_TO_CLAIM && LosingPOTrisk == true){ 
            // send POT to treasury            
            delete POTbank[tokenId];
            uint256 nPOT = staker.nPOT;
            staker.nPOT = nPOT - 1;
            goldpot.safeTransferFrom(address(this), Treasury , tokenId);
            emit PotLost(tokenId, stake.owner);
            }
            else{
                if (unstake) {
                    // send back POT
                    uint256 nPOT = staker.nPOT;
                    staker.nPOT = nPOT - 1;
                    delete POTbank[tokenId];
                    goldpot.safeTransferFrom(address(this), stake.owner, tokenId);
                } else {
                // reset stake time
                stake.value = uint80(block.timestamp);
                }
            }
        emit POTClaimed(tokenId, owed, unstake);
    } 

    /***STAKING CLOV */

    /**
     * adds Cloves Bank and Staker Info
     * @param account the address of the staker
     * @param tokenIds the IDs of the Thief and Polices to stake
     */
    function addManyCLOVToBank(address account, uint256[] calldata tokenIds)
        public
        nonReentrant()
    {   
        ICLOV CLOVES = cloves;
        require(
            (account == _msgSender() && account == tx.origin),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        require(!paused() || msg.sender == owner(), "Paused");
        Stakeinfo memory staker = SInfo[_msgSender()];
        uint256 nCLOV = staker.nCLOV;
        require( (nCLOV + tokenIds.length)< MAX_CLOVE_STAKED , "To many CLOVES staked");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }
            CLOVES.transferFrom(_msgSender(), address(this), tokenIds[i]);

            string memory rarity = CLOVES.getRarityType(tokenIds[i]);
            
            _addCLOVToBank(account, tokenIds[i], rarity);

            realOwnerOfCLOV[tokenIds[i]] = _msgSender();
            
            
            
        }
    }

    /**
     * adds a single PCLOV to the Bank
     * @param account the address of the staker
     * @param tokenId the ID of the Thief to add to the Bank
     */
    function _addCLOVToBank(address account, uint256 tokenId, string memory rarity) internal  {
       ICLOV CLOVES = cloves;
       Stakeinfo memory staker = SInfo[_msgSender()];
        CLOVbank[tokenId] = StakeCLOV({
            owner: account,
            tokenId: uint16(tokenId),
            rarity: rarity 
        });
       
       uint256 bonus = CLOVES.getBonusvalue(tokenId); 
        staker.nCLOV += 1;
        staker.bonus += bonus;

        emit CLOVStaked(account, tokenId, rarity);
    }

    /*** UNSTAKING CLOVES */

    /**
     *Call for unstake multiple cloves
     * @param tokenIds the IDs of the cloves
     */
    function claimManyCLOVFromBank(uint16[] calldata tokenIds)
        external
        nonReentrant()
    {
        require(msg.sender == tx.origin, "Only EOA");
        require(canClaim || msg.sender == owner(), "Claim deactive");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint16 _id = tokenIds[i];

            _claimCLOVFromBank(_id);

            
            realOwnerOfCLOV[_id] = address(0);
            
        }
    }

    /**
     * Unstaking of single Cloves
     * @param tokenId the ID of the Cloves
     */
    function _claimCLOVFromBank(uint256 tokenId)
        internal
        
    {   
        ICLOV CLOVES = cloves;
        StakeCLOV memory clove = CLOVbank[tokenId];
        address owner = clove.owner;
        require(owner == _msgSender(), "SWIPER, NO SWIPING");
        CLOVES.transferFrom(address(this), owner, tokenId);
        // send back PCLOV
        
        Stakeinfo memory staker = SInfo[_msgSender()];
        uint256 bonus = CLOVES.getBonusvalue(tokenId);
        uint256 Stakerbonus = staker.bonus;
        staker.bonus = Stakerbonus - bonus; 
        uint256 nCLOV = staker.nCLOV;
        staker.nCLOV = nCLOV - 1;
        delete CLOVbank[tokenId];
        
        emit CLOVClaimed(tokenId, true, clove.rarity);
    }

   function getPotRewardInfo(uint256 tokenid)  public view returns (address owner, uint256 stakingStart, uint256 nPOT, uint256 ClovesBonus, uint256 owed) {
       Stakeinfo memory staker = SInfo[owner];
       StakePOT memory gpot = POTbank[tokenid];

       owner = gpot.owner;
       stakingStart = gpot.value;
       nPOT = staker.nPOT;
       ClovesBonus = staker.bonus;
       owed = getOwedAmount(tokenid);


       

       return(owner, stakingStart, nPOT, ClovesBonus, owed);

    }

    function getOwedAmount(uint256 tokenid) public view returns(uint256 owed){
        StakePOT memory stake = POTbank[tokenid];
        uint256 val = stake.value <= previous ? startTimestamp : stake.value;
        require(val <= block.timestamp, "Not started yet");
        Stakeinfo memory staker = SInfo[_msgSender()];
        owed = 0;
        // calculating staking reward as owed
        if(staker.nPOT <= 19){
        owed =
            ((block.timestamp - val) *
                (DAILY_LOOT_RATE_0_19 +
                    ((DAILY_LOOT_RATE_0_19 * staker.bonus /100 ))) /
            1 days);
            return owed;
        }

          if(20 <= staker.nPOT && staker.nPOT <= 39){
        owed =
            ((block.timestamp - val) *
                (DAILY_LOOT_RATE_20_39 +
                    ((DAILY_LOOT_RATE_20_39 * staker.bonus /100 ))) /
            1 days);
            return owed;
        }
            if(40 <= staker.nPOT && staker.nPOT <= 59){
        owed =
            ((block.timestamp - val) *
                (DAILY_LOOT_RATE_40_59 +
                    ((DAILY_LOOT_RATE_40_59 * staker.bonus /100 ))) /
            1 days);
            return owed;
        }

        if(60 <= staker.nPOT && staker.nPOT <= 79){
        owed =
            ((block.timestamp - val) *
                (DAILY_LOOT_RATE_60_79 +
                    ((DAILY_LOOT_RATE_60_79 * staker.bonus /100 ))) /
            1 days);
            return owed;
        }
            if(80 <= staker.nPOT && staker.nPOT <= 100){
        owed =
            ((block.timestamp - val) *
                (DAILY_LOOT_RATE_80_100 +
                    ((DAILY_LOOT_RATE_80_100 * staker.bonus /100 ))) /
            1 days);
            return owed;
        }
    }



 

    /***ADMIN */

    function setSettings(uint256 _RATE_0_19,uint256 _RATE_20_39,uint256 _RATE_40_59,uint256 _RATE_60_79,uint256 _RATE_80_100, uint256 exit, uint256 stakedPOT ,uint256 stakedCLOV) external onlyOwner {
        MINIMUM_TO_CLAIM = exit;
        DAILY_LOOT_RATE_0_19 = _RATE_0_19;
        DAILY_LOOT_RATE_20_39 = _RATE_20_39;
        DAILY_LOOT_RATE_40_59 = _RATE_40_59;
        DAILY_LOOT_RATE_60_79 = _RATE_60_79;
        DAILY_LOOT_RATE_80_100 = _RATE_80_100;
        MAX_POT_STAKED = stakedPOT;
        MAX_CLOVE_STAKED = stakedCLOV;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }


    function setClaiming(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function setStart(uint256 start) public onlyOwner {
        previous = startTimestamp;
        startTimestamp = start;
    }

    function setToken(IGOLD _gold) public onlyOwner {
        gold = _gold;
    }

    function setPOT(IERC721 _pot) public onlyOwner {
        pot = _pot;
    }

    function setCLOV(ICLOV _clove) public onlyOwner {
        cloves  = _clove;
    }

    function setCLOVBONUS(uint256 _Pbonus, uint256 _Gbonus, uint256 _Bbonus) public onlyOwner {
        Pbonus  = _Pbonus;
        Gbonus = _Gbonus;
        Bbonus = _Bbonus;
    }

     function setLosingPOTrisk(bool _LosingPOTrisk) public onlyOwner {
        LosingPOTrisk  = _LosingPOTrisk;
       
    }

     function setTreasury(address _Treasury) public onlyOwner {
        Treasury = _Treasury;
       
    }
}