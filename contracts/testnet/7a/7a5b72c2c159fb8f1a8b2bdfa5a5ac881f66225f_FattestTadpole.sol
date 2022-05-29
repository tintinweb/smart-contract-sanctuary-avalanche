/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-28
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract Fly is ERC20 {
    address public owner;

    // whitelist for minting mechanisms
    mapping(address => bool) public zones;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    constructor(string memory _NAME, string memory _SYMBOL)
        ERC20(_NAME, _SYMBOL, 18)
    {
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                            Zones - can mint
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address zone) external onlyOwner {
        delete zones[zone];
    }

    /*///////////////////////////////////////////////////////////////
                                MINT / BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver, uint256 amount) external onlyZone {
        _mint(receiver, amount);
    }

    function burn(address from, uint256 amount) external onlyZone {
        _burn(from, amount);
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

//slither-disable-next-line locked-ether
contract TadpoleNFT is ERC721 {
    address public owner;
    address public breedingSpot;
    address public exchanger;

    /*///////////////////////////////////////////////////////////////
                                  TADPOLES
    //////////////////////////////////////////////////////////////*/

    // 0 Common
    // 1 Rare
    // 2 Exceptional
    // 3 Epic
    // 4 Legendary

    struct Tadpole {
        uint128 category;
        uint64 skin;
        uint56 hat;
        uint8 background;
    }

    mapping(uint256 => Tadpole) public tadpoles;

    uint256 public nextTokenID;
    string public baseURI;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error InvalidTokenID();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    /*///////////////////////////////////////////////////////////////
                           CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    constructor(string memory _NFT_NAME, string memory _NFT_SYMBOL)
        ERC721(_NFT_NAME, _NFT_SYMBOL)
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = _newOwner;
        emit OwnerUpdated(_newOwner);
    }

    function setBreedingSpot(address _breedingSpot) external onlyOwner {
        breedingSpot = _breedingSpot;
    }

    function setExchanger(address _exchanger) external onlyOwner {
        exchanger = _exchanger;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /*///////////////////////////////////////////////////////////////
                           TADPOLE
    //////////////////////////////////////////////////////////////*/

    function _getCategory(uint256 _seed) internal pure returns (uint256) {
        uint256 randomness = _seed % 1000;

        // 0 Common
        // 1 Rare
        // 2 Exceptional
        // 3 Epic
        // 4 Legendary

        if (randomness >= 500) {
            return 0;
        } else if (randomness < 500 && randomness >= 200) {
            return 1;
        } else if (randomness < 200 && randomness >= 50) {
            return 2;
        } else if (randomness < 50 && randomness >= 4) {
            return 3;
        } else {
            return 4;
        }
    }

    function _getHat(uint256 category, uint256 seed)
        internal
        pure
        returns (uint256)
    {
        // 0 Common
        // 1 Rare
        // 2 Exceptional
        // 3 Epic
        // 4 Legendary

        if (category == 4) {
            return seed % 5;
        } else if (category == 3) {
            return seed % 6;
        } else if (category == 2) {
            return seed % 8;
        } else if (category == 1) {
            return seed % 10;
        } else {
            // if (category == 0)
            return seed % 15;
        }
    }

    function mint(address _receiver, uint256 _seed) external {
        if (breedingSpot != msg.sender) revert Unauthorized();

        unchecked {
            uint256 tokenId = nextTokenID++;
            _mint(_receiver, tokenId);

            uint256 category = _getCategory(_seed);

            tadpoles[tokenId] = Tadpole({
                category: uint128(category),
                skin: uint64((_seed >> 1) % 8),
                hat: uint56(_getHat(category, _seed >> 2)),
                background: uint8((_seed >> 3) % 9)
            });
        }
    }

    function burn(address _tadOwner, uint256 _tokenId) external {
        if (exchanger != msg.sender) revert Unauthorized();
        if (ownerOf[_tokenId] != _tadOwner) revert Unauthorized();

        delete tadpoles[_tokenId];

        _burn(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                           ERC721 VIEW
    //////////////////////////////////////////////////////////////*/

    function _getCategoryName(uint256 category)
        internal
        pure
        returns (string memory)
    {
        if (category == 0) {
            return "Common";
        } else if (category == 1) {
            return "Rare";
        } else if (category == 2) {
            return "Exceptional";
        } else if (category == 3) {
            return "Epic";
        } else if (category == 4) {
            return "Legendary";
        }
        return "Undefined";
    }

    function _jsonString(uint256 tokenId) public view returns (string memory) {
        Tadpole memory tadpole = tadpoles[tokenId];
        return
            string(
                bytes.concat(
                    '{"name":"tadpole #',
                    bytes(_toString(tokenId)),
                    '", "description":"Tadpole", "attributes":[',
                    '{"trait_type": "category", "value": "',
                    bytes(_getCategoryName(tadpole.category)),
                    '"},',
                    '{"trait_type": "background", "value": ',
                    bytes(_toString(tadpole.background)),
                    "},",
                    '{"trait_type": "hat", "value": ',
                    bytes(_toString(tadpole.hat)),
                    "},",
                    '{"trait_type": "skin", "value": ',
                    bytes(_toString(tadpole.skin)),
                    "}",
                    "],",
                    '"image":"',
                    bytes(baseURI),
                    bytes(_toString(tokenId)),
                    '"}'
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf[tokenId] == address(0)) revert InvalidTokenID();

        return _jsonString(tokenId);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        //slither-disable-next-line incorrect-equality
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            //slither-disable-next-line weak-prng
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// Tadpole 0x9cd44c2e3b059324fa131f117dec9e89ca1632df
// FattestTadpole 0x7a5b72c2c159fb8f1a8b2bdfa5a5ac881f66225f

contract FattestTadpole {
    // Addresses
    address public immutable FLY;
    address public immutable TADPOLE;
    uint public immutable period = 5 minutes;
    uint public startTs = 0;
    uint public cycle = 0;
    address public owner;
    Winner currentWinner;

    struct Winner {
        address adr;
        uint256 points;
    }

    struct TadpoleOwner {
        uint256 tokenId;
        bool staked;
    }

    // Mappings
    mapping(address => TadpoleOwner) public tadpoleOwners;
    mapping(uint => mapping(address => uint256)) public cyclePoints;
    mapping(address => uint) public historicalWinners;

    // Events
    event UpdatedOwner(address indexed owner);

    // Errors
    error Unauthorized();
    error WrongTokenID();
    error NotStarted();
    error NothingToClaim();
    error AlreadyStaked();

    constructor(address fly, address tadpole) {
        owner = msg.sender;
        FLY = fly;
        TADPOLE = tadpole;
    }

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    // Management methods
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    // Methods
    function isStarted() external view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function _isStarted() private view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function start() external {
        if (currentWinner.points > 0) {
            unchecked {
                historicalWinners[currentWinner.adr]++;
            }
        }
        currentWinner = Winner({
            adr: address(0),
            points: 0
        });
        unchecked {
            cycle++;
        }
        startTs = block.timestamp;
    }

    function canClaim() external view returns (bool) {
        return historicalWinners[msg.sender] > 0;
    }

    function claim() external returns (uint) {
        if (historicalWinners[msg.sender] == 0) {
            revert NothingToClaim();
        }
        uint claimAmount = historicalWinners[msg.sender];
        // TODO::: mint!
        return claimAmount;
    }

    function enter(uint256 tokenId) external {
        if (!_isStarted()) {
            revert NotStarted();
        }
        if (tadpoleOwners[msg.sender].staked) {
            revert AlreadyStaked();
        }
        TadpoleNFT tadpole = TadpoleNFT(TADPOLE);
        tadpoleOwners[msg.sender] = TadpoleOwner({
            tokenId: tokenId,
            staked: true
        });
        tadpole.transferFrom(msg.sender, address(this), tokenId);
        cyclePoints[cycle][msg.sender] = 0;
    }

    function exit() external {
        uint256 tokenId = tadpoleOwners[msg.sender].tokenId;
        TadpoleNFT tadpole = TadpoleNFT(TADPOLE);
        tadpole.transferFrom(address(this), msg.sender, tokenId);
        cyclePoints[cycle][msg.sender] = 0;
        delete tadpoleOwners[msg.sender];
    }

    function getUserPoints() external view returns (uint256) {
        return cyclePoints[cycle][msg.sender];
    }

    function addFlies(uint256 flies) external {
        if (!_isStarted()) {
            revert NotStarted();
        }
        if (!tadpoleOwners[msg.sender].staked) {
            revert WrongTokenID();
        }
        uint256 tokenId = tadpoleOwners[msg.sender].tokenId;
        Fly(FLY).burn(msg.sender, flies);
        (uint128 rarity, , ,) = TadpoleNFT(TADPOLE).tadpoles(tokenId);
        unchecked {
            uint256 points = flies + ((flies * rarity) / 10);
            cyclePoints[cycle][msg.sender] += points;
        }
        if (cyclePoints[cycle][msg.sender] > currentWinner.points) {
            currentWinner.adr = msg.sender;
            currentWinner.points = cyclePoints[cycle][msg.sender];
        }
    }
}