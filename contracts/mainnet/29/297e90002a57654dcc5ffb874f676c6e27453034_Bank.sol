// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Context.sol";
import "./IERC721Receiver.sol";

interface IRandomSource {
    function seed() external view returns (uint256);

    function update(uint256 _seed) external;
}

interface TALES {
    function mint(address to, uint256 amount) external;
}

interface ITalesofAsheaGame {
    struct TalesofAshea {
        bool isAdventurer;
        bool isKing;
        uint8 body;
        uint8 weapon;
        uint8 hat;
        uint8 head;
        uint8 armor;
        uint8 helmet;
        uint8 crown;
        uint8 authority;
        uint8 gen;
    }

    function randomSource() external view returns (IRandomSource);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (TalesofAshea memory);
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

interface IWAVAX {
    function deposit() external payable;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

abstract contract Pauseable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in paused state.
     */
    constructor() {
        _paused = true;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pauseable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pauseable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Bank is Ownable, IERC721Receiver, Pauseable {
    uint256[3] alphasPer = [450, 325, 225];
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        uint80 poolValue;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event AdventurerClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event KingClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event GuildMasterClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    // reference to the ITalesofAsheaGame NFT contract
    ITalesofAsheaGame game;
    // reference to the $TALES contract for minting $TALES earnings
    TALES tales;
    IWAVAX public wAVAX;
    address payable public DAO;
    // maps tokenId to stake for Adventurer
    mapping(uint256 => Stake) public bank;
    //maps tokenId to stake for guild
    mapping(uint256 => Stake) public bankGuildMaster;
    // maps alpha to all King stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each King in Pack
    mapping(uint256 => uint256) public packIndices;
    // maps userClaimed
    mapping(address => uint256) public userClaimed;
    // maps userStaked
    mapping(address => uint256[]) public userStaked;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewardsKing = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewardsGuild = 0;
    // amount of $TALES due for each alpha point staked
    uint256 public talesPerAlpha = 0;
    // amount of $TALES due for each alpha point staked
    uint256 public talesGuildPool = 0;
    //  earn 10000 $TALES per day
    uint256 public DAILY_TALES_RATE = 10000 ether;
    //  must have 2 days  worth of $TALES to unstake or else it's too cold
    uint256 public MINIMUM_TO_EXIT = 2 days; //days
    uint256 public MINIMUM_GUILDMASTER_TO_EXIT = 1.5 days; //days
    // wolves take a 10% tax on all $TALES claimed
    uint256 public TALES_ADVENTURER_CLAIM_KING_TAX = 10;
    // wolves take a 15% tax on all $TALES claimed
    uint256 public TALES_ADVENTURER_CLAIM_GUILDMASTERTAX = 15;
    // wolves take a 70% tax on all $TALES claimed
    uint256 public TALES_ADVENTURER_UNSTAKE_KING_TAX = 70;
    // wolves take a 30% tax on all $TALES claimed
    uint256 public TALES_ADVENTURER_UNSTAKE_GUILDMASTERTAX = 30;
    // wolves take a 20% tax on all $TALES claimed
    uint256 public TALES_GUILDMASTER_CLAIM_KING_TAX = 20;
    // wolves take a 100% tax on all $TALES claimed
    uint256 public TALES_GUILDMASTER_UNSTAKE_KING_TAX = 100;
    // wolves take a 50% tax on all $TALES claimed
    uint256 public TALES_KING_UNSTAKE_GUILDMASTER_TAX = 50;

    uint256 public ClaimTax = 0.01 ether;
    // there will only ever be (roughly) 9.4 billion $TALES earned through staking
    uint256 public MAXIMUM_GLOBAL_TALES = 9400000000 ether;
    address[] public claimUsers;
    // amount of $TALES earned so far
    uint256 public totalTalesEarned;
    uint256 public totalTalesClaimed;
    // number  staked in the Bank
    uint256 public totalAdventurerStaked;
    uint256 public totalGuildMasterStaked;
    uint256 public totalKingStaked;
    // the last time $TALES was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $TALES
    bool public rescueEnabled = false;

    bool private _reentrant = false;
    bool public canClaim = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * @param _game reference to the ITalesofAsheaGame NFT contract
     * @param _tales reference to the $TALES token
     */
    constructor(
        ITalesofAsheaGame _game,
        TALES _tales,
        address payable _DAO,
        IWAVAX _wAVAX
    ) {
        game = _game;
        tales = _tales;
        DAO = _DAO;
        wAVAX = _wAVAX;
    }

    function setBankStats(
        uint256 _lastClaimTimestamp,
        uint256 _totalTalesEarned
    ) public onlyOwner {
        lastClaimTimestamp = _lastClaimTimestamp;
        totalTalesEarned = _totalTalesEarned;
    }

    enum PARAMETER {
        ADVENTURER_CLAIM_KING_TAX,
        ADVENTURER_CLAIM_GUILDMASTERTAX,
        ADVENTURER_UNSTAKE_KING_TAX,
        ADVENTURER_UNSTAKE_GUILDMASTERTAX,
        GUILDMASTER_CLAIM_KING_TAX,
        GUILDMASTER_UNSTAKE_KING_TAX,
        KING_UNSTAKE_GUILDMASTER_TAX,
        ClaimTax
    }

    function setTaxs(PARAMETER _parameter, uint256 _input) public onlyOwner {
        if (_parameter == PARAMETER.ADVENTURER_CLAIM_KING_TAX) {
            // 0
            TALES_ADVENTURER_CLAIM_KING_TAX = _input;
        } else if (_parameter == PARAMETER.ADVENTURER_CLAIM_GUILDMASTERTAX) {
            // 1
            TALES_ADVENTURER_CLAIM_GUILDMASTERTAX = _input;
        } else if (_parameter == PARAMETER.ADVENTURER_UNSTAKE_KING_TAX) {
            // 2
            TALES_ADVENTURER_UNSTAKE_KING_TAX = _input;
        } else if (_parameter == PARAMETER.ADVENTURER_UNSTAKE_GUILDMASTERTAX) {
            // 3
            TALES_ADVENTURER_UNSTAKE_GUILDMASTERTAX = _input;
        } else if (_parameter == PARAMETER.GUILDMASTER_CLAIM_KING_TAX) {
            // 4
            TALES_GUILDMASTER_CLAIM_KING_TAX = _input;
        } else if (_parameter == PARAMETER.GUILDMASTER_UNSTAKE_KING_TAX) {
            // 5
            TALES_GUILDMASTER_UNSTAKE_KING_TAX = _input;
        } else if (_parameter == PARAMETER.KING_UNSTAKE_GUILDMASTER_TAX) {
            // 6
            TALES_KING_UNSTAKE_GUILDMASTER_TAX = _input;
        } else if (_parameter == PARAMETER.ClaimTax) {
            // 7
            ClaimTax = _input;
        }
    }

    function getUserStaked(address _addr) public view returns (uint256) {
        return userStaked[_addr].length;
    }

    function getClaimUsers() public view returns (uint256) {
        return claimUsers.length;
    } 

    /***STAKING */

    /**
     * adds roles to the Bank and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the roles to stake
     */
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(game),
            "DONT GIVE YOUR TOKENS AWAY"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == 0) {
                continue;
            }

            if (_msgSender() != address(game)) {
                // dont do this step if its a mint + stake
                require(
                    game.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                game.transferFrom(_msgSender(), address(this), tokenIds[i]);
            }
            if (isAdventurer(tokenIds[i])) {
                _addAdventurerToBank(account, tokenIds[i]);
            } else if (isKing(tokenIds[i])) {
                _addKingToPack(account, tokenIds[i]);
            } else {
                _addGuildMasterToBank(account, tokenIds[i]);
            }
            userStaked[_msgSender()].push(tokenIds[i]);
        }
    }

    /**
     * adds a single Adventurer to the Bank
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer to add to the Bank
     */
    function _addAdventurerToBank(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        bank[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            poolValue: 0
        });
        totalAdventurerStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    function _addGuildMasterToBank(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarningsGuildMaster
    {
        bankGuildMaster[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp),
            poolValue: uint80(talesGuildPool)
        });
        totalGuildMasterStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single King to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the King to add to the Pack
     */
    function _addKingToPack(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarningsKing
    {
        uint256 alpha = _alphaForKing(tokenId);
        totalAlphaStaked += alpha;
        totalKingStaked += 1;
        // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length;

        // Store the location of the king in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                poolValue: uint80(talesPerAlpha),
                value: uint80(block.timestamp)
            })
        );
        // Add the king to the Pack
        emit TokenStaked(account, tokenId, talesPerAlpha);
    }

    /***CLAIMING / UNSTAKING */
    function claimManyFromBankAndPack(uint16[] calldata tokenIds, bool unstake)
        external
        payable
        nonReentrant
    {
        require(msg.sender == tx.origin, "Only EOA");
        require(canClaim, "Claim deactive");
        require(
            msg.value == tokenIds.length * ClaimTax,
            "Insufficient wallet balance"
        );

        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isAdventurer(tokenIds[i])) {
                owed += _claimAdventurerFromBank(tokenIds[i], unstake);
            } else if (isKing(tokenIds[i])) {
                owed += _claimKingFromPack(tokenIds[i], unstake);
            } else {
                owed += _claimGuildMasterFromBank(tokenIds[i], unstake);
            }
            if (unstake) {
                uint256 index = find(tokenIds[i]);
                removeAtIndex(index);
            }
        }
        if (owed == 0) return;
        userClaimed[_msgSender()] += owed;
        claimUsers.push(_msgSender());
        totalTalesClaimed += owed;
        tales.mint(_msgSender(), owed);
        if (msg.value > 0) {
            wAVAX.deposit{value: msg.value}();
            wAVAX.transfer(DAO, msg.value);
        }
    }

    function _claimAdventurerFromBank(uint256 tokenId, bool unstake)
        internal
        _updateEarnings
        returns (uint256 owed)
    {
        Stake memory stake = bank[tokenId];
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "you can only unstake a adventurer / guildmaster / king if it has at least 20,000 / 15,000 / 20,000 $TALES"
        );
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            owed =
                ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $TALES production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
            // stop earning additional $TALES if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $TALES stolen
                _payKingTax((owed * TALES_ADVENTURER_UNSTAKE_KING_TAX) / 100);
                _payGuildMasterTax(
                    (owed * TALES_ADVENTURER_UNSTAKE_GUILDMASTERTAX) / 100
                );
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back
            delete bank[tokenId];
            totalAdventurerStaked -= 1;
        } else {
            _payKingTax((owed * TALES_ADVENTURER_CLAIM_KING_TAX) / 100);
            _payGuildMasterTax(
                (owed * TALES_ADVENTURER_CLAIM_GUILDMASTERTAX) / 100
            );
            // percentage tax to staked wolves
            owed =
                (owed *
                    (100 -
                        TALES_ADVENTURER_CLAIM_KING_TAX -
                        TALES_ADVENTURER_CLAIM_GUILDMASTERTAX)) /
                100;
            bank[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp),
                poolValue: 0
            });
            // reset stake
        }
        // reset stake
        emit AdventurerClaimed(tokenId, owed, unstake);
    }

    function _claimGuildMasterFromBank(uint256 tokenId, bool unstake)
        internal
        _updateEarningsGuildMaster
        returns (uint256 owed)
    {
        Stake memory stake = bankGuildMaster[tokenId];
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        require(
            !(unstake &&
                block.timestamp - stake.value < MINIMUM_GUILDMASTER_TO_EXIT),
            "you can only unstake a adventurer / guildmaster / king if it has at least 20,000 / 15,000 / 20,000 $TALES"
        );
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            owed =
                ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $TALES production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
            // stop earning additional $TALES if it's all been earned
        }
        owed += talesGuildPool - stake.poolValue;
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $TALES stolen
                _payKingTax((owed * TALES_GUILDMASTER_UNSTAKE_KING_TAX) / 100);
                owed = 0;
            }
            game.transferFrom(address(this), _msgSender(), tokenId);
            // send back
            delete bankGuildMaster[tokenId];
            totalGuildMasterStaked -= 1;
        } else {
            _payKingTax((owed * TALES_GUILDMASTER_CLAIM_KING_TAX) / 100);
            // percentage tax to staked wolves
            owed = (owed * (100 - TALES_GUILDMASTER_CLAIM_KING_TAX)) / 100;
            bankGuildMaster[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp),
                poolValue: uint80(talesGuildPool)
            });
            // reset stake
        }
        emit GuildMasterClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $TALES earnings for a single King and optionally unstake it
     * Kings earn $TALES proportional to their Alpha rank
     * @param tokenId the ID of the King to claim earnings from
     * @param unstake whether or not to unstake the King
     * @return owed - the amount of $TALES earned
     */
    function _claimKingFromPack(uint256 tokenId, bool unstake)
        internal
        _updateEarningsKing
        returns (uint256 owed)
    {
        require(
            game.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _alphaForKing(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "Some NFTs don't belong to you");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "you can only unstake a adventurer / guildmaster / king only if they have at least 20,000 / 15,000 / 20,000 $TALES, which means they have to be staked 2 / 1.5 /2 days more after the last claim"
        );
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            owed =
                ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0;
            // $TALES production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                1 days;
            // stop earning additional $TALES if it's all been earned
        }
        owed += (alpha) * (talesPerAlpha - stake.poolValue);
        // Calculate portion of tokens based on Alpha
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $TALES stolen
                _payGuildMasterTax(
                    (owed * TALES_KING_UNSTAKE_GUILDMASTER_TAX) / 100
                );
                owed =
                    (owed * (100 - TALES_KING_UNSTAKE_GUILDMASTER_TAX)) /
                    100;
            }
            totalAlphaStaked -= alpha;
            totalKingStaked -= 1;
            // Remove Alpha from total staked
            game.transferFrom(address(this), _msgSender(), tokenId);
            // Send back King
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake;
            // Shuffle last King to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop();
            // Remove duplicate
            delete packIndices[tokenId];
            // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                poolValue: uint80(talesPerAlpha),
                value: uint80(block.timestamp)
            });
            // reset stake
        }
        emit KingClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isAdventurer(tokenId)) {
                stake = bank[tokenId];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                game.transferFrom(address(this), _msgSender(), tokenId);
                delete bank[tokenId];
                totalAdventurerStaked -= 1;
                emit AdventurerClaimed(tokenId, 0, true);
            } else if (isKing(tokenId)) {
                alpha = _alphaForKing(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                totalAlphaStaked -= alpha;
                // Remove Alpha from total staked
                game.transferFrom(address(this), _msgSender(), tokenId);
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake;
                // Shuffle last King to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop();
                // Remove duplicate
                delete packIndices[tokenId];
                // Delete old mapping
                emit KingClaimed(tokenId, 0, true);
            } else {
                stake = bankGuildMaster[tokenId];
                require(
                    stake.owner == _msgSender(),
                    "Some NFTs don't belong to you"
                );
                game.transferFrom(address(this), _msgSender(), tokenId);
                delete bankGuildMaster[tokenId];
                totalGuildMasterStaked -= 1;
            }
        }
    }

    /***ACCOUNTING */

    /**
     * add $TALES to claimable pot for the Pack
     * @param amount $TALES to add to the pot
     */
    function _payKingTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked wolves
            unaccountedRewardsKing += amount;
            // keep track of $TALES due to wolves
            return;
        }
        // makes sure to include any unaccounted $TALES
        talesPerAlpha += (amount + unaccountedRewardsKing) / totalAlphaStaked;
        unaccountedRewardsKing = 0;
    }

    function _payGuildMasterTax(uint256 amount) internal {
        if (totalGuildMasterStaked == 0) {
            // if there's no staked wolves
            unaccountedRewardsGuild += amount;
            // keep track of $TALES due to wolves
            return;
        }
        // makes sure to include any unaccounted $TALES
        talesGuildPool +=
            (amount + unaccountedRewardsGuild) /
            totalGuildMasterStaked;
        unaccountedRewardsGuild = 0;
    }

    /**
     * tracks $TALES earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            totalTalesEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalAdventurerStaked *
                    DAILY_TALES_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    modifier _updateEarningsGuildMaster() {
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            totalTalesEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalGuildMasterStaked *
                    DAILY_TALES_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    modifier _updateEarningsKing() {
        if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
            totalTalesEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalKingStaked *
                    DAILY_TALES_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /***ADMIN */

    function setSettings(
        uint256 rate,
        uint256 exit,
        uint256 maxTales,
        uint256 guildmasterExit
    ) external onlyOwner {
        DAILY_TALES_RATE = rate;
        MINIMUM_TO_EXIT = exit;
        MINIMUM_GUILDMASTER_TO_EXIT = guildmasterExit;
        MAXIMUM_GLOBAL_TALES = maxTales;
    }

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function isAdventurer(uint256 tokenId)
        public
        view
        returns (bool adventurer)
    {
        adventurer = game.getTokenTraits(tokenId).isAdventurer;
    }

    function isKing(uint256 tokenId) public view returns (bool king) {
        king = game.getTokenTraits(tokenId).isKing;
    }

    function calculate(uint256 tokenId) public view returns (uint256 owed) {
        if (isKing(tokenId)) {
            uint256 alpha = _alphaForKing(tokenId);
            Stake memory stake = pack[alpha][packIndices[tokenId]];
            if (stake.owner == address(0)) return 0;
            if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
                // $TALES production stopped already
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
                // stop earning additional $TALES if it's all been earned
            }
            owed += (alpha) * (talesPerAlpha - stake.poolValue);
        } else if (isAdventurer(tokenId)) {
            Stake memory stake = bank[tokenId];
            if (stake.owner == address(0)) return 0;
            if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
            }
        } else {
            Stake memory stake = bankGuildMaster[tokenId];
            if (stake.owner == address(0)) return 0;
            if (totalTalesEarned < MAXIMUM_GLOBAL_TALES) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0;
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_TALES_RATE) /
                    1 days;
            }
            owed += talesGuildPool - stake.poolValue;
        }
    }


    function _alphaForKing(uint256 tokenId) internal view returns (uint256) {
        return alphasPer[game.getTokenTraits(tokenId).authority];
    }

    function randomOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0 && totalGuildMasterStaked == 0)
            return address(0x0);
        uint256 temp = totalAlphaStaked == 0
            ? totalGuildMasterStaked
            : totalAlphaStaked;
        uint256 bucket = (seed & 0xFFFFFFFF) % temp;
        // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        for (uint256 i = 0; i <= 2; i++) {
            cumulative += pack[alphasPer[i]].length * alphasPer[i];
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random King with that alpha score
            if (bucket % 10 == 0) {
                return
                    bankGuildMaster[
                        (seed & 0xFFFFFFFF) % totalGuildMasterStaked
                    ].owner;
            }
            return pack[alphasPer[i]][seed % pack[alphasPer[i]].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed,
                        totalAdventurerStaked,
                        totalGuildMasterStaked,
                        totalAlphaStaked,
                        lastClaimTimestamp
                    )
                )
            ) ^ game.randomSource().seed();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function setGame(ITalesofAsheaGame _nGame) public onlyOwner {
        game = _nGame;
    }

    function setClaiming(bool _canClaim) public onlyOwner {
        canClaim = _canClaim;
    }

    function setDao(address _dao) public onlyOwner {
        DAO = payable(_dao);
    }

    function setWAVAX(address _wAVAX) public onlyOwner {
        wAVAX = IWAVAX(_wAVAX);
    }

    function find(uint256 value) public view returns (uint256) {
        uint256 i = 0;
        while (userStaked[_msgSender()][i] != value) {
            i++;
        }
        return i;
    }

    function removeAtIndex(uint256 index) internal returns (bool) {
        if (index >= userStaked[_msgSender()].length) return false;
        for (uint256 i = index; i < userStaked[_msgSender()].length - 1; i++) {
            userStaked[_msgSender()][i] = userStaked[_msgSender()][i + 1];
        }
        delete userStaked[_msgSender()][userStaked[_msgSender()].length - 1];
        userStaked[_msgSender()].pop();
        return true;
    }
}