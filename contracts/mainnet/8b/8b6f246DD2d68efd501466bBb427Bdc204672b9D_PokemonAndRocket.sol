// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pauseable.sol";
import "./ERC721Enumerable.sol";
import "./IPokemon.sol";
import "./ArenaV3.sol";
import "./ITraits.sol";
import "./IPOKE.sol";
import "./Pauseable.sol";
import "./ISeed.sol";
import "./IArena.sol";
contract PokemonAndRocket is IPokemon, ERC721Enumerable, Ownable, Pauseable {

    // mint price
    uint256 public MINT_PRICE = 1 ether;
    uint256 public MAX_MINT = 30;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => Pokemon) public tokenTraits;
    mapping (address => bool) private whiteListedMap;

    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    IArena public arena;

    IPOKE public poke;
    // reference to Traits
    ITraits public traits;

    ISeed public randomSource;

    bool private _reentrant = false;
    bool private stakingActive = true;

    constructor(IPOKE _poke, ITraits _traits, uint256 _maxTokens) ERC721("Pokemon&Rocket", 'POKE') {
        poke = _poke;
        traits = _traits;

        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = 1000;
    }

    function setRandomSource(ISeed _seed) external onlyOwner {
        randomSource = _seed;
    }

    function burnRest(uint16 _rest) public onlyOwner {
        minted += _rest;
    }

    function setWhiteListed(address[] memory addresses) onlyOwner public {
        for(uint256 i = 0; addresses.length > i; i++ ) {
            whiteListedMap[addresses[i]] = true;
        }
    }

    function isWhiteListed(address recipient) public view returns (bool) {
        return whiteListedMap[recipient];
    }

    function buyWhiteListed(address recipient) internal {
        whiteListedMap[recipient] = false;
    }
    /***EXTERNAL */

    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        require(!stake || stakingActive, "Staking not activated");

        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= MAX_MINT, "Invalid mint amount");

        if (minted < PAID_TOKENS && !isWhiteListed(msg.sender) ) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(amount * MINT_PRICE == msg.value, "Invalid payment amount");
        } else {
            require(msg.value == 0);
            buyWhiteListed(msg.sender);
        }

        uint256 totalPokeCost = 0;
        uint16[] memory tokenIds = new uint16[](amount);
        address[] memory owners = new address[](amount);
        uint256 seed;
        uint256 firstMinted = minted;

        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            randomSource.update(minted ^ seed);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            totalPokeCost += mintCost(minted);
            if (!stake || recipient != _msgSender()) {
                owners[i] = recipient;
            } else {
                tokenIds[i] = minted;
                owners[i] = address(arena);
            }

        }

        if (totalPokeCost > 0) poke.burn(_msgSender(), totalPokeCost);

        for (uint i = 0; i < owners.length; i++) {
            uint id = firstMinted + i + 1;
            if (!stake || owners[i] != _msgSender()) {
                _safeMint(owners[i], id);
            }
        }
        if (stake) arena.addManyToBankAndPack(_msgSender(), tokenIds);
    }

    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 2 / 4) return 15000 ether;
        if (tokenId <= MAX_TOKENS * 3 / 4) return 30000 ether;
        return 45000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override  {
        if (_msgSender() != address(arena))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    /***INTERNAL */

    function generate(uint256 tokenId, uint256 seed) internal returns (Pokemon memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender();
        // top 10 bits haven't been used
        address pokemon = arena.randomPoliceOwner(seed >> 144);
        // 144 bits reserved for trait selection
        if (pokemon == address(0x0)) return _msgSender();
        return pokemon;
    }


    function selectTraits(uint256 seed) internal view returns (Pokemon memory t) {
        t.isPokemon = (seed & 0xFFFF) % 10 != 0;
        if (!t.isPokemon) {
            t.alphaIndex = 5 + uint8(random(seed) % 3) ;
        }else{
            t.CP = uint8(random(seed) % 200);
        }
    }


    function structToHash(Pokemon memory s) internal pure returns (uint256) {
        return uint256(keccak256(
                abi.encodePacked(
                    s.isPokemon,
                    s.CP, 
                    s.alphaIndex
                )
            ));
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            ))) ^ randomSource.seed();
    }

    /***READ */

    function getTokenTraits(uint256 tokenId) external view override returns (Pokemon memory) {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    /***ADMIN */


    function setArena(address _arena) external onlyOwner {
        arena = IArena(_arena);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }


    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        traits.tokenURI(tokenId);
    }

    function changePrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    function setStakingActive(bool _staking) public onlyOwner {
        stakingActive = _staking;
    }

    function setTraits(ITraits addr) public onlyOwner {
        traits = addr;
    }
}