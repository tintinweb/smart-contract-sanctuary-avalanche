// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

interface IRandomSource {
    function seed() external view returns (uint256);

    function update(uint256 _seed) external;
}

interface IBank {
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds)
        external;

    function randomOwner(uint256 seed) external view returns (address);
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

interface ITALES {
    function burn(address from, uint256 amount) external;
}

interface IWAVAX {
    function deposit() external payable;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8);
}

contract TalesofAsheaGame is ERC721Enumerable, Ownable {
    // mint price
    uint256 public MINT_PRICE = 1.6 ether;
    //white mint price
    uint256 public WHITE_MINT_PRICE = 1.4 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    uint256 public WHITE_SALE_TIME;
    uint256 public PUBLIC_SALE_TIME;
    // number of tokens have been minted so far
    uint16 public minted;
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
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => TalesofAshea) public tokenTraits;
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;
    //whiteListed
    mapping(address => bool) public whiteListed;
    mapping(address => uint256) public mintCount;
    //mintd
    uint256 public adventurerMinted;
    uint256 public guildmasterMinted;
    uint256 public kingMinted;
    //stolen
    uint256 public adventurerStolen;
    uint256 public guildmasterStolen;
    uint256 public kingStolen;
    address payable public DAO;
    IBank public bank;
    // reference to $TALES for burning on mint
    ITALES public tales;
    IWAVAX public wAVAX;
    // reference to Traits
    ITraits public traits;
    IRandomSource public randomSource;
    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    /**
     * instantiates contract and rarity tables
     */
    constructor(
        ITALES _tales,
        ITraits _traits,
        IRandomSource _randomSource,
        address payable _DAO,
        IWAVAX _wAVAX,
        uint256 _maxTokens,
        uint256 _WHITE_SALE_TIME,
        uint256 _PUBLIC_SALE_TIME
    ) ERC721("Tales of Ashea Game", "TOAG") {
        tales = _tales;
        traits = _traits;
        randomSource = _randomSource;
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;

        WHITE_SALE_TIME = _WHITE_SALE_TIME;
        PUBLIC_SALE_TIME = _PUBLIC_SALE_TIME;
        wAVAX = _wAVAX;
        DAO = _DAO;
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All NFTs are minted");
        require(amount > 0 && amount <= 15, "Invalid mint amount"); //1-10
        require(block.timestamp > WHITE_SALE_TIME, "Mint didn't start");
        uint256 costValue = MINT_PRICE;
        if (block.timestamp < PUBLIC_SALE_TIME && minted <= 1000) {
            require(
                minted + amount <= 1000,
                "The number you mint exceed the rest amount of whitelist NFTs"
            );
            require(whiteListed[_msgSender()], "Not in Whitelist, pls wait until 10:45 UTC");
            require(
                mintCount[_msgSender()] + amount <= 5,
                "Each WL address can mint up to 5 NFTs by 1.4 AVAX"
            );
            costValue = WHITE_MINT_PRICE;
        }
        if (minted < PAID_TOKENS) {
            require(
                minted + amount <= PAID_TOKENS,
                "The number you mint exceed the rest amount of gen0 NFTs"
            );
            require(
                amount * costValue == msg.value,
                "Insufficient wallet balance"
            );
        } else {
            require(msg.value == 0);
        }

        uint256 totalTALESCost = 0;
        address[] memory owners = new address[](amount);
        uint256 seed;
        uint256 firstMinted = minted;

        for (uint256 i = 0; i < amount; i++) {
            minted++;
            mintCount[_msgSender()]++;
            seed = random(minted);
            randomSource.update(minted ^ seed);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            totalTALESCost += mintCost(minted);
            TalesofAshea memory t = tokenTraits[minted];
            t.isAdventurer ? adventurerMinted++ : t.isKing
                ? kingMinted++
                : guildmasterMinted++;

            owners[i] = recipient;
            if (recipient != _msgSender()) {
                t.isAdventurer ? adventurerStolen++ : t.isKing
                    ? kingStolen++
                    : guildmasterStolen++;
            }
        }
        if (totalTALESCost > 0) tales.burn(_msgSender(), totalTALESCost);
        if (msg.value > 0) {
            wAVAX.deposit{value: msg.value}();
            wAVAX.transfer(DAO, msg.value);
        }
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 id = firstMinted + i + 1;
            _safeMint(owners[i], id);
        }
    }

    /**
     * the first 20% are paid in AVAX
     * the next 20% are 10000 $TALES
     * the next 20% are 20000 $TALES
     * the next 20% are 30000 $TALES
     * the final 20% are 40000 $TALES
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= (MAX_TOKENS * 2) / 5) return 10000 ether;
        if (tokenId <= (MAX_TOKENS * 3) / 5) return 20000 ether;
        if (tokenId <= (MAX_TOKENS * 4) / 5) return 30000 ether;
        return 40000 ether;
    }

    function getGen(uint256 tokenId) public view returns (uint8) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= (MAX_TOKENS * 2) / 5) return 1;
        if (tokenId <= (MAX_TOKENS * 3) / 5) return 2;
        if (tokenId <= (MAX_TOKENS * 4) / 5) return 3;
        return 4;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        // Hardcode the Bank's approval so that users don't have to waste gas approving
        if (_msgSender() != address(bank))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /***INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 tokenId, uint256 seed)
        internal
        returns (TalesofAshea memory t)
    {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        return traits.selectTrait(seed, traitType);
    }

    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0)
            return _msgSender();
        // top 10 bits haven't been used
        address recipient = bank.randomOwner(seed >> 144);
        // 144 bits reserved for trait selection
        if (recipient == address(0x0)) return _msgSender();
        return recipient;
    }

    function selectTraits(uint256 seed)
        internal
        view
        returns (TalesofAshea memory t)
    {
        t.gen = getGen(minted);
        t.isAdventurer = (seed & 0xFFFF) % 100 > 11;
        t.isKing = (seed & 0xFFFF) % 100 < 2;
        uint8 shift = t.isAdventurer ? 0 : t.isKing ? 20 : 10; // 0 10 20
        seed >>= 16;
        if (t.isKing) {
            t.authority = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
            seed >>= 16;
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
            seed >>= 16;
            t.crown = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
            seed >>= 16;
            t.body = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
            seed >>= 16;
        } else if (t.isAdventurer) {
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
            seed >>= 16;
            t.hat = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
            seed >>= 16;
            t.head = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
            seed >>= 16;
            t.body = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
            seed >>= 16;
        } else {
            t.weapon = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
            seed >>= 16;
            t.armor = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
            seed >>= 16;
            t.helmet = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
            seed >>= 16;
            t.body = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
            seed >>= 16;
        }
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(TalesofAshea memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.isAdventurer,
                        s.isKing,
                        s.weapon,
                        s.hat,
                        s.head,
                        s.armor,
                        s.helmet,
                        s.crown,
                        s.authority,
                        s.gen,
                        s.body
                    )
                )
            );
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
                        seed
                    )
                )
            ) ^ randomSource.seed();
    }

    /***READ */

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (TalesofAshea memory)
    {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view returns (uint256) {
        return PAID_TOKENS;
    }

    /***ADMIN */

    /**
     * called after deployment so that the contract can get random police thieves
     * @param _bank the address of the Bank
     */
    function setBank(address _bank) external onlyOwner {
        bank = IBank(_bank);
    }

    function setRandomSource(address _randomSource) external onlyOwner {
        randomSource = IRandomSource(_randomSource);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * enables owner to pause / unpause minting
     */

    /***RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }

    function changePrice(uint256 _price, uint256 _whitePrice) public onlyOwner {
        MINT_PRICE = _price;
        WHITE_MINT_PRICE = _whitePrice;
    }

    function changeSaleTime(uint256 _WHITE_SALE_TIME, uint256 _PUBLIC_SALE_TIME)
        public
        onlyOwner
    {
        WHITE_SALE_TIME = _WHITE_SALE_TIME;
        PUBLIC_SALE_TIME = _PUBLIC_SALE_TIME;
    }

    function setTraits(ITraits addr) public onlyOwner {
        traits = addr;
    }

    function setDao(address _dao) public onlyOwner {
        DAO = payable(_dao);
    }

    function setWAVAX(address _wAVAX) public onlyOwner {
        wAVAX = IWAVAX(_wAVAX);
    }

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }
        return true;
    }
}