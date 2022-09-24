// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./interface/IHopper.sol";
import "./interface/IFly.sol";
import "./interface/ITadpoleMinter.sol";
import {ERC721} from "../lib/solmate/src/tokens/ERC721.sol";

interface IBreedingSeed {
    function getSeed(uint256) external returns (uint256);
}

contract BreedingV2 {
    address public owner;
    bool public emergency;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    IFly public immutable FLY;
    IHopperNFT public immutable HOPPER;
    ITadpoleMinter public immutable TADPOLE_MINTER;

    /*///////////////////////////////////////////////////////////////
                            MUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    //random seed contract
    address public BREEDING_SEED;

    /*///////////////////////////////////////////////////////////////
                                HOPPERS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public hopperOwners;
    mapping(uint256 => uint256) public hopperUnlockTime;
    uint256 public breedingCost;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error OnlyEOAAllowed();
    error TooSoon();
    error WrongTokenID();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);
    event Roll(uint256 rand, uint256 chance);

    /*///////////////////////////////////////////////////////////////
                           CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    constructor(address _fly, address _hopper, address _tadpole_minter, uint256 _breedingCost, address _breedingSeed) {
        owner = msg.sender;

        FLY = IFly(_fly);
        HOPPER = IHopperNFT(_hopper);
        TADPOLE_MINTER = ITadpoleMinter(_tadpole_minter);

        breedingCost = _breedingCost;
        BREEDING_SEED = _breedingSeed;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setBreedingCost(uint256 _breedingCost) external onlyOwner {
        breedingCost = _breedingCost;
    }

    function setBreedingSeed(address _newSeed) external onlyOwner {
        BREEDING_SEED = _newSeed;
    }

    function enableEmergency() external onlyOwner {
        // no going back
        emergency = true;
    }

    /*///////////////////////////////////////////////////////////////
                                TADPOLE
    //////////////////////////////////////////////////////////////*/

    function _roll(uint256 _tokenId) internal {
        HopperNFT.Hopper memory hopper = IHopperNFT(HOPPER).getHopper(_tokenId);

        uint256 rand = IBreedingSeed(BREEDING_SEED).getSeed(_tokenId);

        uint256 chance;

        unchecked {
            chance = (90000 * uint256(hopper.fertility) + 9000 * 3 * uint256(hopper.level)) / 400;
        }

        emit Roll(rand % 10_000, chance);
        if ((rand % 10_000) < chance) {
            TADPOLE_MINTER.mintTadpole(msg.sender, rand >> 8);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/

    function enter(uint256 _tokenId) external {
        // solhint-disable-next-line
        if (msg.sender != tx.origin) {
            revert OnlyEOAAllowed();
        }

        hopperOwners[_tokenId] = msg.sender;

        unchecked {
            hopperUnlockTime[_tokenId] = block.timestamp + 1 days;
        }

        HOPPER.transferFrom(msg.sender, address(this), _tokenId);
        IFly(FLY).burn(msg.sender, breedingCost);
    }

    function exit(uint256 _tokenId) external {
        if (hopperOwners[_tokenId] != msg.sender) {
            revert Unauthorized();
        }
        if (hopperUnlockTime[_tokenId] > block.timestamp) {
            revert TooSoon();
        }

        _roll(_tokenId);

        delete hopperOwners[_tokenId];
        delete hopperUnlockTime[_tokenId];

        HOPPER.transferFrom(address(this), msg.sender, _tokenId);
    }

    function emergencyExit(uint256[] calldata tokenIds, address user) external {
        if (!emergency) {
            revert Unauthorized();
        }

        uint256 numTokens = tokenIds.length;
        for (uint256 i; i < numTokens;) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this hopper
            if (hopperOwners[tokenId] != user) {
                revert WrongTokenID();
            }

            //slither-disable-next-line costly-loop
            delete hopperOwners[tokenId];
            HOPPER.transferFrom(address(this), user, tokenId);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IHopperNFT {
    error InsufficientAmount();
    error InvalidTokenID();
    error MaxLength25();
    error MintLimit();
    error NameTaken();
    error OnlyAlphanumeric();
    error OnlyEOAAllowed();
    error OnlyLvL100();
    error ReservedAmountInvalid();
    error TooSoon();
    error Unauthorized();

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event LevelUp(uint256 tokenId);
    event NameChange(uint256 tokenId);
    event OwnerUpdated(address indexed newOwner);
    event Rebirth(uint256 tokenId);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event UnlabeledData(string key, uint256 tokenId);
    event UpdatedNameFee(uint256 namefee);

    function LEGENDARY_ID_START() external view returns (uint256);

    function MAX_PER_ADDRESS() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function MINT_COST() external view returns (uint256);

    function WL_MINT_COST() external view returns (uint256);

    function _jsonString(uint256 tokenId) external view returns (string memory);

    function addZones(address[] memory _zones) external;

    function approve(address spender, uint256 id) external;

    function balanceOf(address) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function changeHopperName(uint256 tokenId, string memory _newName) external returns (uint256);

    function freeMerkleRoot() external view returns (bytes32);

    function freeMint(uint256 numberOfMints, uint256 totalGiven, bytes32[] memory proof) external;

    function freeRedeemed(address) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function getData(string memory _key, uint256 _tokenId) external view returns (bytes32);

    function getGlobalData(string memory _key) external view returns (bytes32);

    function getHopper(uint256 tokenId) external view returns (HopperNFT.Hopper memory);

    function getHopperName(uint256 tokenId) external view returns (string memory name);

    function getHopperWithData(string[] memory _keys, uint256 _tokenId)
        external
        view
        returns (HopperNFT.Hopper memory hopper, bytes32[] memory arrData);

    function hopperMaxAttributeValue() external view returns (uint256);

    function hoppers(uint256)
        external
        view
        returns (
            uint200 level,
            uint16 rebirths,
            uint8 strength,
            uint8 agility,
            uint8 vitality,
            uint8 intelligence,
            uint8 fertility
        );

    function hoppersLength() external view returns (uint256);

    function hoppersNames(uint256) external view returns (string memory);

    function imageURL() external view returns (string memory);

    function indexer(uint256) external view returns (uint256);

    function isApprovedForAll(address, address) external view returns (bool);

    function levelUp(uint256 tokenId) external;

    function name() external view returns (string memory);

    function nameFee() external view returns (uint256);

    function normalMint(uint256 numberOfMints) external payable;

    function owner() external view returns (address);

    function ownerOf(uint256) external view returns (address);

    function preSaleOpenTime() external view returns (uint256);

    function rebirth(uint256 _tokenId) external;

    function removeZone(address _zone) external;

    function reserved() external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id) external;

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory _baseURI) external;

    function setData(string memory _key, uint256 _tokenId, bytes32 _data) external;

    function setGlobalData(string memory _key, bytes32 _data) external;

    function setHopperMaxAttributeValue(uint256 _hopperMaxAttributeValue) external;

    function setImageURL(string memory _imageURL) external;

    function setNameChangeFee(uint256 _nameFee) external;

    function setOwner(address newOwner) external;

    function setSaleDetails(uint256 _preSaleOpenTime, bytes32 _wlMerkleRoot, bytes32 _freeMerkleRoot, uint256 _reserved)
        external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function symbol() external view returns (string memory);

    function takenNames(bytes32) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(address from, address to, uint256 id) external;

    function unlabeledData(string memory, uint256) external view returns (bytes32);

    function unlabeledGlobalData(string memory) external view returns (bytes32);

    function unsetData(string memory _key, uint256 _tokenId) external;

    function unsetGlobalData(string memory _key) external;

    function whitelistMint(bytes32[] memory proof) external payable;

    function withdraw() external;

    function wlMerkleRoot() external view returns (bytes32);

    function wlRedeemed(address) external view returns (uint256);

    function zones(address) external view returns (bool);
}

interface HopperNFT {
    struct Hopper {
        uint200 level;
        uint16 rebirths;
        uint8 strength;
        uint8 agility;
        uint8 vitality;
        uint8 intelligence;
        uint8 fertility;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.12;

interface IFly {
    error Unauthorized();

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event OwnerUpdated(address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function addZones(address[] memory _zones) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function burn(address from, uint256 amount) external;

    function decimals() external view returns (uint8);

    function mint(address receiver, uint256 amount) external;

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function removeZone(address zone) external;

    function setOwner(address newOwner) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function zones(address) external view returns (bool);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ITadpoleMinter {
    error Unauthorited();

    event OwnerUpdated(address indexed user, address indexed newOwner);

    function MinterContract(address) external view returns (bool);

    function burnTadpole(address _tadOwner, uint256 _tokenId) external;

    function mintTadpole(address _receiver, uint256 _seed) external;

    function owner() external view returns (address);

    function setMinterContract(address _contract, bool _value) external;

    function setOwner(address newOwner) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}