/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-29
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// File: contracts/ERC721.sol


pragma solidity 0.8.12;

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
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
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

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
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

        require(ownerOf[id] != address(0), "NOT_MINTED");

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
// File: contracts/Tadpole.sol


pragma solidity 0.8.12;


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
// File: contracts/ERC20.sol


pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
// File: contracts/Fly.sol


pragma solidity 0.8.12;


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
// File: contracts/SafeTransferLib.sol


pragma solidity >=0.8.0;


/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}
// File: contracts/Hopper.sol


pragma solidity 0.8.12;




//slither-disable-next-line locked-ether
contract HopperNFT is ERC721 {
    using SafeTransferLib for address;

    address public owner;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable MAX_PER_ADDRESS;
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MINT_COST;
    uint256 public immutable WL_MINT_COST;
    uint256 public immutable LEGENDARY_ID_START;

    /*///////////////////////////////////////////////////////////////
                              SALE DETAILS
    //////////////////////////////////////////////////////////////*/

    uint256 public reserved;
    uint256 public preSaleOpenTime;
    bytes32 public freeMerkleRoot;
    bytes32 public wlMerkleRoot;
    mapping(address => uint256) public freeRedeemed;
    mapping(address => uint256) public wlRedeemed;

    /*///////////////////////////////////////////////////////////////
                                HOPPERS
    //////////////////////////////////////////////////////////////*/

    struct Hopper {
        uint200 level; // capped by zone
        uint16 rebirths;
        uint8 strength;
        uint8 agility;
        uint8 vitality;
        uint8 intelligence;
        uint8 fertility;
    }

    mapping(uint256 => Hopper) public hoppers;
    uint256 public hoppersLength;
    uint256 public hopperMaxAttributeValue;

    mapping(uint256 => uint256) public indexer;

    string public baseURI;
    string public imageURL;

    /*///////////////////////////////////////////////////////////////
                             
    //////////////////////////////////////////////////////////////*/

    // whitelist for leveling up
    mapping(address => bool) public zones;

    // unlabeled data [key -> tokenid -> data] for potential future zones
    mapping(string => mapping(uint256 => bytes32)) public unlabeledData;

    // unlabeled data [key -> data] for potential future zones
    mapping(string => bytes32) public unlabeledGlobalData;

    /*///////////////////////////////////////////////////////////////
                            HOPPER NAMES
    //////////////////////////////////////////////////////////////*/

    uint256 public nameFee;
    mapping(bytes32 => bool) public takenNames;
    mapping(uint256 => string) public hoppersNames;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event LevelUp(uint256 tokenId);
    event NameChange(uint256 tokenId);
    event UpdatedNameFee(uint256 namefee);
    event Rebirth(uint256 tokenId);
    event UnlabeledData(string key, uint256 tokenId);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MintLimit();
    error InsufficientAmount();
    error Unauthorized();
    error InvalidTokenID();
    error MaxLength25();
    error OnlyEOAAllowed();
    error NameTaken();
    error OnlyLvL100();
    error TooSoon();
    error ReservedAmountInvalid();
    error OnlyAlphanumeric();

    constructor(
        string memory _NFT_NAME,
        string memory _NFT_SYMBOL,
        uint256 _NAME_FEE
    ) ERC721(_NFT_NAME, _NFT_SYMBOL) {
        owner = msg.sender;

        MINT_COST = 1.75 ether;
        WL_MINT_COST = 1.2 ether;
        MAX_SUPPLY = 10_000;
        MAX_PER_ADDRESS = 10;
        LEGENDARY_ID_START = 9968;

        nameFee = _NAME_FEE;
        hopperMaxAttributeValue = 10;

        unchecked {
            preSaleOpenTime = type(uint256).max - 30 minutes;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyOwnerOrZone() {
        if (msg.sender != owner && !zones[msg.sender]) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setHopperMaxAttributeValue(uint256 _hopperMaxAttributeValue)
        external
        onlyOwner
    {
        hopperMaxAttributeValue = _hopperMaxAttributeValue;
    }

    function setNameChangeFee(uint256 _nameFee) external onlyOwner {
        nameFee = _nameFee;
        emit UpdatedNameFee(_nameFee);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setImageURL(string calldata _imageURL) external onlyOwner {
        imageURL = _imageURL;
    }

    function setSaleDetails(
        uint256 _preSaleOpenTime,
        bytes32 _wlMerkleRoot,
        bytes32 _freeMerkleRoot,
        uint256 _reserved
    ) external onlyOwner {
        preSaleOpenTime = _preSaleOpenTime;

        freeMerkleRoot = _freeMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;

        reserved = _reserved;
    }

    function withdraw() external onlyOwner {
        owner.safeTransferETH(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                    HOPPER VALID ZONES/ADVENTURES
    //////////////////////////////////////////////////////////////*/

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address _zone) external onlyOwner {
        delete zones[_zone];
    }

    /*///////////////////////////////////////////////////////////////
                            Unlabeled Data
    //////////////////////////////////////////////////////////////*/

    function setGlobalData(string calldata _key, bytes32 _data)
        external
        onlyOwnerOrZone
    {
        unlabeledGlobalData[_key] = _data;
    }

    function unsetGlobalData(string calldata _key) external onlyOwnerOrZone {
        delete unlabeledGlobalData[_key];
    }

    function getGlobalData(string calldata _key)
        external
        view
        returns (bytes32)
    {
        return unlabeledGlobalData[_key];
    }

    function setData(
        string calldata _key,
        uint256 _tokenId,
        bytes32 _data
    ) external onlyOwnerOrZone {
        unlabeledData[_key][_tokenId] = _data;

        emit UnlabeledData(_key, _tokenId);
    }

    function unsetData(string calldata _key, uint256 _tokenId)
        external
        onlyOwnerOrZone
    {
        delete unlabeledData[_key][_tokenId];
    }

    function getData(string calldata _key, uint256 _tokenId)
        external
        view
        returns (bytes32)
    {
        return unlabeledData[_key][_tokenId];
    }

    function getHopperWithData(string[] calldata _keys, uint256 _tokenId)
        external
        view
        returns (Hopper memory hopper, bytes32[] memory arrData)
    {
        hopper = hoppers[_tokenId];

        uint256 length = _keys.length;
        arrData = new bytes32[](length);

        for (uint256 i; i < length; ) {
            arrData[i] = unlabeledData[_keys[i]][_tokenId];
            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        HOPPER LEVEL SYSTEM
    //////////////////////////////////////////////////////////////*/

    function rebirth(uint256 _tokenId) external {
        Hopper memory hopper = hoppers[_tokenId];

        if (ownerOf[_tokenId] != msg.sender) revert Unauthorized();
        if (hopper.level < 100) revert OnlyLvL100();

        uint256 _hopperMaxAttributeValue = hopperMaxAttributeValue;

        unchecked {
            if (hopper.strength < _hopperMaxAttributeValue) {
                hoppers[_tokenId].strength = uint8(hopper.strength + 1);
            }

            if (hopper.intelligence < _hopperMaxAttributeValue) {
                hoppers[_tokenId].intelligence = uint8(hopper.intelligence + 1);
            }

            if (hopper.agility < _hopperMaxAttributeValue) {
                hoppers[_tokenId].agility = uint8(hopper.agility + 1);
            }

            if (hopper.vitality < _hopperMaxAttributeValue) {
                hoppers[_tokenId].vitality = uint8(hopper.vitality + 1);
            }

            if (hopper.fertility < _hopperMaxAttributeValue) {
                hoppers[_tokenId].fertility = uint8(hopper.fertility + 1);
            }

            ++hoppers[_tokenId].rebirths;
        }

        hoppers[_tokenId].level = 1;

        delete unlabeledData["LEVEL_GAUGE_KEY"][_tokenId];

        emit Rebirth(_tokenId);
    }

    function levelUp(uint256 tokenId) external onlyZone {
        // max level is checked on zone
        unchecked {
            ++(hoppers[tokenId].level);
        }
        emit LevelUp(tokenId);
    }

    function changeHopperName(uint256 tokenId, string calldata _newName)
        external
        onlyZone
        returns (uint256)
    {
        bytes memory newName = bytes(_newName);
        uint256 newLength = newName.length;

        if (newLength > 25) revert MaxLength25();

        // Checks it's only alphanumeric characters
        for (uint256 i; i < newLength; ) {
            bytes1 char = newName[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) //.
            ) {
                revert OnlyAlphanumeric();
            }
            unchecked {
                ++i;
            }
        }

        // Checks new name uniqueness
        bytes32 nameHash = keccak256(newName);
        if (takenNames[nameHash]) revert NameTaken();

        // Free previous name
        takenNames[keccak256(bytes(hoppersNames[tokenId]))] = false;

        // Reserve name
        takenNames[nameHash] = true;
        hoppersNames[tokenId] = _newName;

        emit NameChange(tokenId);

        return nameFee;
    }

    /*///////////////////////////////////////////////////////////////
                          HOPPER GENERATION
    //////////////////////////////////////////////////////////////*/

    function enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number)
                    )
                )
            );
    }

    //slither-disable-next-line weak-prng
    function generate(
        uint256 seed,
        uint256 minAttributeValue,
        uint256 randCap
    ) internal pure returns (Hopper memory) {
        unchecked {
            return
                Hopper({
                    strength: uint8(
                        ((seed >> (8 * 1)) % randCap) + minAttributeValue
                    ),
                    agility: uint8(
                        ((seed >> (8 * 2)) % randCap) + minAttributeValue
                    ),
                    vitality: uint8(
                        ((seed >> (8 * 3)) % randCap) + minAttributeValue
                    ),
                    intelligence: uint8(
                        ((seed >> (8 * 4)) % randCap) + minAttributeValue
                    ),
                    fertility: uint8(
                        ((seed >> (8 * 5)) % randCap) + minAttributeValue
                    ),
                    level: 1,
                    rebirths: 0
                });
        }
    }

    function _mintHoppers(uint256 numberOfMints, uint256 preTotalHoppers)
        internal
    {
        uint256 seed = enoughRandom();

        uint256 _indexerLength;
        unchecked {
            _indexerLength = MAX_SUPPLY - preTotalHoppers;
        }

        for (uint256 i; i < numberOfMints; ) {
            seed >>= i;

            // Find the next available tokenID
            //slither-disable-next-line weak-prng
            uint256 index = seed % _indexerLength;
            uint256 tokenId = indexer[index];

            if (tokenId == 0) {
                tokenId = index;
            }

            // Swap the picked tokenId for the last element
            unchecked {
                --_indexerLength;
            }

            uint256 last = indexer[_indexerLength];
            if (last == 0) {
                // this _indexerLength value had not been picked before
                indexer[index] = _indexerLength;
            } else {
                // this _indexerLength value had been picked and swapped before
                indexer[index] = last;
            }

            // Mint Hopper and generate its attributes
            _mint(msg.sender, tokenId);

            if (tokenId >= LEGENDARY_ID_START) {
                hoppers[tokenId] = generate(seed, 5, 6);
            } else {
                hoppers[tokenId] = generate(seed, 1, 10);
            }
            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            HOPPER MINTING
    //////////////////////////////////////////////////////////////*/

    function _handleMint(uint256 numberOfMints) internal {
        // solhint-disable-next-line
        if (msg.sender != tx.origin) revert OnlyEOAAllowed();

        unchecked {
            uint256 totalHoppers = hoppersLength + numberOfMints;

            if (
                numberOfMints > MAX_PER_ADDRESS ||
                totalHoppers > (MAX_SUPPLY - reserved)
            ) revert MintLimit();

            _mintHoppers(numberOfMints, totalHoppers - numberOfMints);
            hoppersLength = totalHoppers;
        }
    }

    function freeMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external {
        unchecked {
            if (block.timestamp < preSaleOpenTime + 30 minutes)
                revert TooSoon();
        }

        if (freeRedeemed[msg.sender] + numberOfMints > totalGiven)
            revert Unauthorized();
        if (reserved < numberOfMints) revert ReservedAmountInvalid();

        if (
            !MerkleProof.verify(
                proof,
                freeMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            freeRedeemed[msg.sender] += numberOfMints;
            reserved -= numberOfMints;
        }

        _handleMint(numberOfMints);
    }

    function whitelistMint(bytes32[] memory proof) external payable {
        if (wlRedeemed[msg.sender] == 1) revert Unauthorized();
        if (block.timestamp < preSaleOpenTime) revert TooSoon();
        if (WL_MINT_COST > msg.value) revert InsufficientAmount();

        if (
            !MerkleProof.verify(
                proof,
                wlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert Unauthorized();

        wlRedeemed[msg.sender] = 1;

        _handleMint(1);
    }

    function normalMint(uint256 numberOfMints) external payable {
        unchecked {
            if (block.timestamp < preSaleOpenTime + 30 minutes)
                revert TooSoon();
        }
        if (MINT_COST * numberOfMints > msg.value) revert InsufficientAmount();

        _handleMint(numberOfMints);
    }

    /*///////////////////////////////////////////////////////////////
                          HOPPER VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getHopper(uint256 tokenId) external view returns (Hopper memory) {
        return hoppers[tokenId];
    }

    function getHopperName(uint256 tokenId)
        public
        view
        returns (string memory name)
    {
        name = hoppersNames[tokenId];

        if (bytes(name).length == 0) {
            name = string(bytes.concat("hopper #", bytes(_toString(tokenId))));
        }
    }

    function _getTraits(Hopper memory hopper)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    '{"trait_type": "rebirths", "value": ',
                    bytes(_toString(hopper.rebirths)),
                    "},",
                    '{"trait_type": "strength", "value": ',
                    bytes(_toString(hopper.strength)),
                    "},",
                    '{"trait_type": "agility", "value": ',
                    bytes(_toString(hopper.agility)),
                    "},",
                    '{"trait_type": "vitality", "value": ',
                    bytes(_toString(hopper.vitality)),
                    "},",
                    '{"trait_type": "intelligence", "value": ',
                    bytes(_toString(hopper.intelligence)),
                    "},",
                    '{"trait_type": "fertility", "value": ',
                    bytes(_toString(hopper.fertility)),
                    "}"
                )
            );
    }

    function _jsonString(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        Hopper memory hopper = hoppers[tokenId];

        //slither-disable-next-line incorrect-equality
        if (hopper.level == 0) revert InvalidTokenID();

        return
            string(
                bytes.concat(
                    '{"name":"',
                    bytes(getHopperName(tokenId)),
                    '", "description":"Hopper", "attributes":[',
                    '{"trait_type": "level", "value": ',
                    bytes(_toString(hopper.level)),
                    "},",
                    bytes(_getTraits(hopper)),
                    "],",
                    '"image":"',
                    bytes(imageURL),
                    bytes(_toString(tokenId)),
                    '.png"}'
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        //slither-disable-next-line incorrect-equality
        if (hoppers[tokenId].level == 0) revert InvalidTokenID();

        return string(bytes.concat(bytes(baseURI), bytes(_toString(tokenId))));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
// File: contracts/Breeding.sol


pragma solidity 0.8.12;





interface IBreedingSeed{
    function getSeed(uint256) external view returns (uint256);
}

contract Breeding {
    address public owner;
    bool    public emergency;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable FLY;
    address public immutable HOPPER;
    address public immutable TADPOLE;

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
    constructor(
        address _fly,
        address _hopper,
        address _tadpole,
        uint256 _breedingCost,
        address _breedingSeed
    ) {
        owner = msg.sender;

        FLY = _fly;
        HOPPER = _hopper;
        TADPOLE = _tadpole;

        breedingCost = _breedingCost;
        BREEDING_SEED = _breedingSeed;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
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
        HopperNFT.Hopper memory hopper = HopperNFT(HOPPER).getHopper(_tokenId);

        uint256 rand = IBreedingSeed(BREEDING_SEED).getSeed(_tokenId);

        uint256 chance;

        unchecked {
            chance =
                (90000 *
                    uint256(hopper.fertility) +
                    9000 *
                    3 *
                    uint256(hopper.level)) /
                400;
        }

        emit Roll(rand % 10_000, chance);
        if ((rand % 10_000) < chance)
            TadpoleNFT(TADPOLE).mint(msg.sender, rand >> 8);
    }

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/

    function enter(uint256 _tokenId) external {
        // solhint-disable-next-line
        if (msg.sender != tx.origin) revert OnlyEOAAllowed();

        hopperOwners[_tokenId] = msg.sender;

        unchecked {
            hopperUnlockTime[_tokenId] = block.timestamp + 1 days;
        }

        ERC721(HOPPER).transferFrom(msg.sender, address(this), _tokenId);
        Fly(FLY).burn(msg.sender, breedingCost);
    }

    function exit(uint256 _tokenId) external {
        if (hopperOwners[_tokenId] != msg.sender) revert Unauthorized();
        if (hopperUnlockTime[_tokenId] > block.timestamp) revert TooSoon();

        _roll(_tokenId);

        delete hopperOwners[_tokenId];
        delete hopperUnlockTime[_tokenId];

        ERC721(HOPPER).transferFrom(address(this), msg.sender, _tokenId);
    }

    function emergencyExit(uint256[] calldata tokenIds, address user) external {
        if (!emergency) revert Unauthorized();

        uint256 numTokens = tokenIds.length;
        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this hopper
            if (hopperOwners[tokenId] != user) revert WrongTokenID();

            //slither-disable-next-line costly-loop
            delete hopperOwners[tokenId];
            ERC721(HOPPER).transferFrom(address(this), user, tokenId);

            unchecked {
                ++i;
            }
        }
    }
}