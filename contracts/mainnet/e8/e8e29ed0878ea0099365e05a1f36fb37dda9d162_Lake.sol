/**
 *Submitted for verification at snowtrace.io on 2022-03-12
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

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
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
}// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)



/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
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
}contract Ballot {
    address public owner;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable VEFLY;
    address public immutable FLY;

    /*///////////////////////////////////////////////////////////////
                              ZONES
    //////////////////////////////////////////////////////////////*/

    address[] public arrZones;
    mapping(address => bool) public zones;
    mapping(address => uint256) public zonesVotes;

    mapping(address => mapping(address => uint256)) public zonesUserVotes;
    mapping(address => uint256) public userVeFlyUsed;

    /*///////////////////////////////////////////////////////////////
                              EMISSIONS
    //////////////////////////////////////////////////////////////*/

    uint256 public bonusEmissionRate;
    uint256 public rewardSnapshot;
    uint256 public countRewardRate;

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error TooSoon();
    error NotEnoughVeFly();

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(address _flyAddress, address _veFlyAddress) {
        owner = msg.sender;
        rewardSnapshot = type(uint256).max;
        FLY = _flyAddress;
        VEFLY = _veFlyAddress;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function openBallot(uint256 _countRewardRate, uint256 _bonusEmissionRate)
        external
        onlyOwner
    {
        rewardSnapshot = block.timestamp;
        countRewardRate = _countRewardRate;
        bonusEmissionRate = _bonusEmissionRate;
    }

    function closeBallot() external onlyOwner {
        rewardSnapshot = type(uint256).max;
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate)
        external
        onlyOwner
    {
        bonusEmissionRate = _bonusEmissionRate;
    }

    function setCountRewardRate(uint256 _countRewardRate) external onlyOwner {
        countRewardRate = _countRewardRate;
    }

    /*///////////////////////////////////////////////////////////////
                                ZONES
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            address zone = _zones[i];
            arrZones.push(zone);
            zones[zone] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(uint256 index) external onlyOwner {
        address removed = arrZones[index];
        arrZones[index] = arrZones[arrZones.length - 1];
        arrZones.pop();
        delete zones[removed];
    }

    /*///////////////////////////////////////////////////////////////
                            VOTING
    //////////////////////////////////////////////////////////////*/

    //slither-disable-next-line costly-loop
    function forceUnvote(address _user) external {
        if (msg.sender != VEFLY) revert Unauthorized();

        uint256 length = arrZones.length;

        for (uint256 i; i < length; ) {
            address zone = arrZones[i];

            uint256 zoneUserVotes = zonesUserVotes[zone][_user];

            if (zoneUserVotes > 0) {
                zonesVotes[zone] -= zoneUserVotes;
                delete userVeFlyUsed[_user];
                delete zonesUserVotes[zone][_user];

                // Done already by veFly on its _forceUncastAllVotes
                // veFly(VEFLY).unsetHasVoted(user)

                Zone(zone).forceUnvote(_user);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _updateVotes(address user, uint256 vefly) internal {
        zonesVotes[msg.sender] =
            zonesVotes[msg.sender] +
            vefly -
            zonesUserVotes[msg.sender][user];

        zonesUserVotes[msg.sender][user] = vefly;
    }

    function vote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        uint256 totalVeFly = userVeFlyUsed[user] + vefly;

        if (totalVeFly > veFly(VEFLY).balanceOf(user)) revert NotEnoughVeFly();

        if (vefly > 0) {
            userVeFlyUsed[user] = totalVeFly;

            unchecked {
                _updateVotes(user, zonesUserVotes[msg.sender][user] + vefly);
            }

            // First time he has voted
            if (totalVeFly == vefly) {
                veFly(VEFLY).setHasVoted(user);
            }
        }
    }

    function unvote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        uint256 _userVeFlyUsed = userVeFlyUsed[user];
        if (_userVeFlyUsed < vefly) revert NotEnoughVeFly();

        uint256 remainingVeFly;
        unchecked {
            remainingVeFly = _userVeFlyUsed - vefly;
        }

        userVeFlyUsed[user] = remainingVeFly;

        uint256 zoneUserVotes = zonesUserVotes[msg.sender][user];

        if (zoneUserVotes < vefly) revert NotEnoughVeFly();

        unchecked {
            _updateVotes(user, zoneUserVotes - vefly);
        }

        if (remainingVeFly == 0) veFly(VEFLY).unsetHasVoted(user);
    }

    /*///////////////////////////////////////////////////////////////
                            COUNTING
    //////////////////////////////////////////////////////////////*/

    function countReward() public view returns (uint256) {
        uint256 _rewardSnapshot = rewardSnapshot;

        if (block.timestamp < _rewardSnapshot) return 0;

        return countRewardRate * (block.timestamp - _rewardSnapshot);
    }

    function count() external {
        uint256 reward = countReward();
        rewardSnapshot = block.timestamp;

        uint256 totalVotes;
        address[] memory _arrZones = arrZones;
        uint256 length = _arrZones.length;

        for (uint256 i; i < length; ) {
            unchecked {
                totalVotes += zonesVotes[_arrZones[i]];
                ++i;
            }
        }

        for (uint256 i; i < length; ) {
            if (totalVotes == 0) {
                Zone(_arrZones[i]).setBonusEmissionRate(0);
            } else {
                Zone(_arrZones[i]).setBonusEmissionRate(
                    (bonusEmissionRate * zonesVotes[_arrZones[i]]) / totalVotes
                );
            }
            unchecked {
                ++i;
            }
        }

        if (reward > 0) {
            // solhint-disable-next-line avoid-tx-origin
            Fly(FLY).mint(tx.origin, reward);
        }
    }
}
// solhint-disable-next-line
contract veFly {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "veFLY";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "veFLY";

    address public immutable FLY;

    /*///////////////////////////////////////////////////////////////
                           FLY/VEFLY GENERATION
    //////////////////////////////////////////////////////////////*/

    struct GenerationDetails {
        uint128 maxRatio;
        uint64 generationRateNumerator;
        uint64 generationRateDenominator;
    }

    GenerationDetails public genDetails;

    mapping(address => uint256) public flyBalanceOf;
    mapping(address => uint256) private veFlyBalance;
    mapping(address => uint256) private userSnapshot;

    /*///////////////////////////////////////////////////////////////
                              VOTING
    //////////////////////////////////////////////////////////////*/

    address[] public arrValidBallots;
    mapping(address => bool) public validBallots;
    mapping(address => mapping(address => bool)) public hasUserVoted;

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidAmount();
    error InvalidProposal();

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedOwner(address indexed owner);
    event AddedBallot(address indexed ballot);
    event RemovedBallot(address indexed ballot);

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _flyAddress,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator,
        uint256 _maxRatio
    ) {
        owner = msg.sender;

        FLY = _flyAddress;

        genDetails = GenerationDetails({
            maxRatio: uint128(_maxRatio),
            generationRateNumerator: uint64(_generationRateNumerator),
            generationRateDenominator: uint64(_generationRateDenominator)
        });
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setGenerationDetails(
        uint256 _maxRatio,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator
    ) external onlyOwner {
        GenerationDetails storage gen = genDetails;
        gen.maxRatio = uint128(_maxRatio);
        gen.generationRateNumerator = uint64(_generationRateNumerator);
        gen.generationRateDenominator = uint64(_generationRateDenominator);
    }

    /*///////////////////////////////////////////////////////////////
                               BALLOTS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBallot() {
        if (!validBallots[msg.sender]) revert Unauthorized();
        _;
    }

    function addBallot(address ballot) external onlyOwner {
        if (!validBallots[ballot]) {
            arrValidBallots.push(ballot);
            validBallots[ballot] = true;
            emit AddedBallot(ballot);
        }
    }

    function removeBallot(uint256 index) external onlyOwner {
        address removed = arrValidBallots[index];

        arrValidBallots[index] = arrValidBallots[arrValidBallots.length - 1];
        arrValidBallots.pop();

        delete validBallots[removed];

        emit RemovedBallot(removed);
    }

    function _forceUncastAllVotes() internal {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            address ballot = arrValidBallots[i];
            delete hasUserVoted[ballot][msg.sender];

            Ballot(ballot).forceUnvote(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function setHasVoted(address user) external onlyBallot {
        hasUserVoted[msg.sender][user] = true;
    }

    function unsetHasVoted(address user) external onlyBallot {
        delete hasUserVoted[msg.sender][user];
    }

    /*///////////////////////////////////////////////////////////////
                               STAKING
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external {
        //slither-disable-next-line incorrect-equality
        if (genDetails.maxRatio == 0) revert Unauthorized();

        // Reset veFly calculations
        veFlyBalance[msg.sender] = balanceOf(msg.sender);
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            flyBalanceOf[msg.sender] += amount;
        }

        // slither-disable-next-line unchecked-transfer
        Fly(FLY).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        if (flyBalanceOf[msg.sender] < amount) revert InvalidAmount();

        // Reset veFly calculations
        delete veFlyBalance[msg.sender];
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            flyBalanceOf[msg.sender] -= amount;
        }

        _forceUncastAllVotes();

        // slither-disable-next-line unchecked-transfer
        Fly(FLY).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               veFly
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) public view returns (uint256) {
        GenerationDetails memory gen = genDetails;

        uint256 flyBalance = flyBalanceOf[account];

        uint256 veBalance = veFlyBalance[account] +
            ((flyBalance * gen.generationRateNumerator) *
                (block.timestamp - userSnapshot[account])) /
            gen.generationRateDenominator;

        uint256 maxVe = gen.maxRatio * flyBalance;
        if (veBalance > maxVe) {
            return maxVe;
        } else {
            return veBalance;
        }
    }

    function hasUserVotedAny(address account) external view returns (bool) {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            if (hasUserVoted[arrValidBallots[i]][account]) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            // Equivalent to require(y != 0 && (x == 0 || (x * baseUnit) / x == baseUnit))
            if iszero(and(iszero(iszero(y)), or(iszero(x), eq(div(z, x), baseUnit)))) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z)
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z)
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z)
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z)
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z)
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z)
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}
abstract contract Zone {
    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable FLY;
    address public immutable VE_FLY;
    address public immutable HOPPER;

    /*///////////////////////////////////////////////////////////////
                                HOPPERS
    //////////////////////////////////////////////////////////////*/
    string public LEVEL_GAUGE_KEY;

    mapping(uint256 => address) public hopperOwners;
    mapping(uint256 => uint256) public hopperBaseShare;
    mapping(address => uint256) public rewards;

    address public owner;
    address public ballot;
    bool public emergency;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards NFT
    //////////////////////////////////////////////////////////////*/
    uint256 public emissionRate;

    uint256 public totalBaseShare;
    uint256 public lastUpdatedTime;
    uint256 public rewardPerShareStored;

    mapping(address => uint256) public baseSharesBalance;
    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public userMaxFlyGeneration;

    mapping(address => uint256) public generatedPerShareStored;
    mapping(uint256 => uint256) public tokenCapFilledPerShare;

    uint256 public flyLevelCapRatio;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards veFLY
    //////////////////////////////////////////////////////////////*/
    uint256 public bonusEmissionRate;

    uint256 public totalVeShare;
    uint256 public lastBonusUpdatedTime;
    uint256 public bonusRewardPerShareStored;

    mapping(address => uint256) public veSharesBalance;
    mapping(address => uint256) public userBonusRewardPerSharePaid;
    mapping(address => uint256) public veFlyBalance;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error UnfitHopper();
    error WrongTokenID();
    error NoHopperStaked();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);
    event UpdatedBallot(address indexed ballot);
    event UpdatedEmission(uint256 emissionRate);

    /*///////////////////////////////////////////////////////////////
                           CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    constructor(
        address fly,
        address vefly,
        address hopper
    ) {
        owner = msg.sender;

        FLY = fly;
        VE_FLY = vefly;
        HOPPER = hopper;

        flyLevelCapRatio = 3;
        LEVEL_GAUGE_KEY = "LEVEL_GAUGE_KEY";
        lastUpdatedTime = block.timestamp;
        lastBonusUpdatedTime = block.timestamp;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyBallotOrOwner() {
        if (msg.sender != owner && msg.sender != ballot) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function enableEmergency() external onlyOwner {
        // no going back
        emergency = true;
    }

    function setBallot(address _ballot) external onlyOwner {
        ballot = _ballot;
        emit UpdatedBallot(_ballot);
    }

    function setEmissionRate(uint256 _emissionRate) external onlyOwner {
        _updateBaseRewardPerShareStored();

        emissionRate = _emissionRate;
        emit UpdatedEmission(_emissionRate);
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate)
        external
        onlyBallotOrOwner
    {
        _updateBonusRewardPerShareStored();

        bonusEmissionRate = _bonusEmissionRate;
    }

    function setFlyLevelCapRatio(uint256 _flyLevelCapRatio) external onlyOwner {
        flyLevelCapRatio = _flyLevelCapRatio;
    }

    /*///////////////////////////////////////////////////////////////
                        HOPPER GENERATION CAP
    //////////////////////////////////////////////////////////////*/

    function getUserBonusGeneratedFly(
        address account,
        uint256 _totalUserBonusShares
    ) public view returns (uint256, uint256) {
        // userMaxFlyGeneration gets updated at _updateAccountBaseReward which happens before this is called
        uint256 cappedFly = userMaxFlyGeneration[account];
        uint256 generatedFly = ((_totalUserBonusShares *
            (bonusRewardPerShare() - userBonusRewardPerSharePaid[account])) /
            1e18);

        return (
            generatedFly > cappedFly ? cappedFly : generatedFly,
            generatedFly
        );
    }

    function getUserGeneratedFly(address account, uint256 _totalUserBaseShares)
        public
        view
        returns (uint256, uint256)
    {
        uint256 cappedFly = userMaxFlyGeneration[account];
        uint256 generatedFly = ((_totalUserBaseShares *
            (baseRewardPerShare() - userRewardPerSharePaid[account])) / 1e18);

        return (
            generatedFly > cappedFly ? cappedFly : generatedFly,
            generatedFly
        );
    }

    function _updateHopperGenerationData(
        address _account,
        uint256 _totalAccountKindShares,
        bool isBonus
    ) internal returns (uint256) {
        uint256 cappedFly;
        uint256 generatedFly;

        if (isBonus) {
            (cappedFly, generatedFly) = getUserBonusGeneratedFly(
                _account,
                _totalAccountKindShares
            );

            // Makes calculations easier, since we don't need to add another
            //    state keeping track of generatedPerVeshare
            generatedPerShareStored[_account] += (generatedFly /
                baseSharesBalance[_account]);
        } else {
            (cappedFly, generatedFly) = getUserGeneratedFly(
                _account,
                _totalAccountKindShares
            );
            generatedPerShareStored[_account] += (generatedFly /
                _totalAccountKindShares);
        }
        return cappedFly;
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDS ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function _updateAccountRewards(address _account) internal {
        _updateAccountBaseReward(_account, baseSharesBalance[_account]);
        _updateAccountBonusReward(_account, veSharesBalance[_account]);
    }

    /*///////////////////////////////////////////////////////////////
                           BASE REWARDS
    //////////////////////////////////////////////////////////////*/

    function baseRewardPerShare() public view returns (uint256) {
        uint256 _totalBaseShare = totalBaseShare;
        //slither-disable-next-line incorrect-equality
        if (_totalBaseShare == 0) {
            return rewardPerShareStored;
        }
        return
            rewardPerShareStored +
            (((block.timestamp - lastUpdatedTime) * emissionRate * 1e18) /
                _totalBaseShare);
    }

    function _updateBaseRewardPerShareStored() internal {
        rewardPerShareStored = baseRewardPerShare();
        lastUpdatedTime = block.timestamp;
    }

    function _updateAccountBaseReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBaseRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFly = _updateHopperGenerationData(
                _account,
                _totalAccountShares,
                false
            );

            unchecked {
                rewards[_account] += cappedFly;
            }
            userMaxFlyGeneration[_account] -= cappedFly;
        }

        userRewardPerSharePaid[_account] = rewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                           BONUS REWARDS
    //////////////////////////////////////////////////////////////*/

    function bonusRewardPerShare() public view returns (uint256) {
        uint256 _totalVeShare = totalVeShare;
        //slither-disable-next-line incorrect-equality
        if (_totalVeShare == 0) {
            return bonusRewardPerShareStored;
        }
        return
            bonusRewardPerShareStored +
            (((block.timestamp - lastBonusUpdatedTime) *
                bonusEmissionRate *
                1e18) / _totalVeShare);
    }

    function _updateBonusRewardPerShareStored() internal {
        bonusRewardPerShareStored = bonusRewardPerShare();
        lastBonusUpdatedTime = block.timestamp;
    }

    function _updateAccountBonusReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBonusRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFly = _updateHopperGenerationData(
                _account,
                _totalAccountShares,
                true
            );

            unchecked {
                rewards[_account] += cappedFly;
            }
            userMaxFlyGeneration[_account] -= cappedFly;
        }
        userBonusRewardPerSharePaid[_account] = bonusRewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                    NAMES & LEVELING
    //////////////////////////////////////////////////////////////*/

    function payAction(uint256 flyRequired, bool useOwnRewards) internal {
        if (useOwnRewards) {
            uint256 _rewards = rewards[msg.sender];

            // Pays from the pending rewards
            if (_rewards >= flyRequired) {
                unchecked {
                    rewards[msg.sender] -= flyRequired;
                    flyRequired = 0;
                }
            } else if (_rewards > 0) {
                delete rewards[msg.sender];
                unchecked {
                    flyRequired -= _rewards;
                }
            }
        }

        // Sender pays for action. Will revert, if not enough balance
        if (flyRequired > 0) {
            Fly(FLY).burn(msg.sender, flyRequired);
        }
    }

    function changeHopperName(
        uint256 tokenId,
        string calldata name,
        bool useOwnRewards
    ) external {
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check hopper ownership
        address zoneHopperOwner = hopperOwners[tokenId];
        if (zoneHopperOwner != msg.sender) {
            // Saves gas in certain paths
            if (HopperNFT(HOPPER).ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        payAction(
            HopperNFT(HOPPER).changeHopperName(tokenId, name), // returns price
            useOwnRewards
        );
    }

    function _getLevelUpCost(uint256 level) internal pure returns (uint256) {
        unchecked {
            ++level;

            // x**(1.43522) / 7.5 for x >= 21 where x is next level
            // packing costs in 7 bits

            if (level > 1 && level < 21) {
                return (level * 1e18) >> 1;
            } else if (level >= 21 && level < 51) {
                return
                    ((0x1223448501f3c74e1b3464c172c54a9426488901e3c70d183058a >>
                        (7 * (level - 21))) & 127) * 1e18;
            } else if (level >= 51 && level < 81) {
                return
                    ((0x23c68b0e14180f9ebc76e9c376cd5a3262c17ae5ab15a9509d325 >>
                        (7 * (level - 51))) & 127) * 1e18;
            } else if (level >= 81 && level < 101) {
                return
                    ((0xc58705ebb6ed59af5aad3a5467ce9b2e549 >>
                        (7 * (level - 81))) & 127) * 1e18;
            } else {
                return type(uint256).max;
            }
        }
    }

    //slither-disable-next-line reentrancy-no-eth
    function levelUp(uint256 tokenId, bool useOwnRewards) external {
        HopperNFT IHOPPER = HopperNFT(HOPPER);
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check hopper ownership
        address zoneHopperOwner = hopperOwners[tokenId];
        if (zoneHopperOwner != msg.sender) {
            // Saves gas in certain paths
            if (IHOPPER.ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        HopperNFT.Hopper memory hopper = IHOPPER.getHopper(tokenId);

        // Update owners shares if hopper is staked
        if (zoneHopperOwner == msg.sender) {
            // Updated above if true
            if (!useOwnRewards) {
                _updateAccountRewards(msg.sender);
            }

            // Fill hopper gauge so we can find whats the remaining
            (, uint256 remainingGauge) = _updateHopperGaugeFill(tokenId);

            // Calculate the baseShare that we need to subtract from the user and total
            uint256 prevHopperShare = _calculateBaseShare(hopper);
            unchecked {
                ++hopper.level;
            }
            // Calculate the baseShare that we need to add to the user and total
            uint256 newHopperShare = _calculateBaseShare(hopper);

            // Calculate new baseShares
            uint256 diff = newHopperShare - prevHopperShare;
            unchecked {
                uint256 newBaseShare = baseSharesBalance[msg.sender] + diff;
                baseSharesBalance[msg.sender] = newBaseShare;

                totalBaseShare += diff;

                // Update new value of veShares
                _updateVeShares(newBaseShare, 0, false);
            }

            // Update the new cap
            userMaxFlyGeneration[msg.sender] += (_getGaugeLimit(hopper.level) -
                remainingGauge);

            // Make sure getLevelUpCost is passed its current level
            unchecked {
                --hopper.level;
            }
        }

        payAction(getLevelUpCost(hopper.level), useOwnRewards);

        IHOPPER.levelUp(tokenId);

        // Reset Hopper internal gauge
        IHOPPER.setData(LEVEL_GAUGE_KEY, tokenId, 0);
    }

    /*///////////////////////////////////////////////////////////////
                    STAKE / UNSTAKE NFT && CLAIM FLY
    //////////////////////////////////////////////////////////////*/

    function enter(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 flyCapIncrease;

        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Resets this hopper generation tracking
            tokenCapFilledPerShare[tokenId] = generatedPerShareStored[
                msg.sender
            ];

            (
                HopperNFT.Hopper memory hopper,
                uint256 hopperGauge,
                uint256 gaugeLimit
            ) = _getHopperAndGauge(tokenId);

            if (!canEnter(hopper)) revert UnfitHopper();

            unchecked {
                // Increment user shares
                _baseShares += _calculateBaseShare(hopper);
            }

            // Update the maximum FLY this user can generate
            flyCapIncrease += (gaugeLimit - hopperGauge);

            // Hopper Accounting
            hopperOwners[tokenId] = msg.sender;
            HopperNFT(HOPPER).transferFrom(msg.sender, address(this), tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;
        unchecked {
            userMaxFlyGeneration[msg.sender] += flyCapIncrease;

            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }

        _updateVeShares(_baseShares, 0, false);
    }

    //slither-disable-next-line reentrancy-no-eth
    function exit(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 flyCapDecrease;

        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this hopper
            if (hopperOwners[tokenId] != msg.sender) revert WrongTokenID();

            (
                uint256 _hopperShare,
                uint256 _remainingGauge
            ) = _updateHopperGaugeFill(tokenId);

            // Decrement user shares
            _baseShares -= _hopperShare;

            // Update the maximum FLY this user can generate
            flyCapDecrease += _remainingGauge;

            // Hopper Accounting
            //slither-disable-next-line costly-loop
            delete hopperOwners[tokenId];
            HopperNFT(HOPPER).transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;
        userMaxFlyGeneration[msg.sender] -= flyCapDecrease;
        unchecked {
            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }
        _updateVeShares(_baseShares, 0, false);
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
            HopperNFT(HOPPER).transferFrom(address(this), user, tokenId);

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            CLAIMING
    //////////////////////////////////////////////////////////////*/

    function claimable(address _account) external view returns (uint256) {
        uint256 cappedFly = userMaxFlyGeneration[_account];

        (uint256 gen, ) = getUserGeneratedFly(
            _account,
            baseSharesBalance[_account]
        );
        (uint256 bonusGen, ) = getUserBonusGeneratedFly(
            _account,
            veSharesBalance[_account]
        );

        gen += bonusGen;
        cappedFly = gen > cappedFly ? cappedFly : gen;

        unchecked {
            return rewards[_account] + cappedFly;
        }
    }

    function claim() external {
        _updateAccountRewards(msg.sender);

        uint256 _accountRewards = rewards[msg.sender];
        delete rewards[msg.sender];

        Fly(FLY).mint(msg.sender, _accountRewards);
    }

    /*///////////////////////////////////////////////////////////////
                            VOTE veFLY 
    //////////////////////////////////////////////////////////////*/

    function _calcVeShare(uint256 accountTotalBaseShares, uint256 vefly)
        internal
        pure
        returns (uint256)
    {
        return FixedPointMathLib.sqrt(accountTotalBaseShares * vefly);
    }

    //slither-disable-next-line reentrancy-no-eth
    function _updateVeShares(
        uint256 baseShares,
        uint256 veFlyAmount,
        bool incrementVeFlyAmount
    ) internal {
        uint256 beforeVeShare = veSharesBalance[msg.sender];
        if (veFlyAmount > 0) {
            // Ballot checks if the user has the veFly amount necessary, otherwise reverts
            if (incrementVeFlyAmount) {
                //slither-disable-next-line reentrancy-benign
                Ballot(ballot).vote(msg.sender, veFlyAmount);
                unchecked {
                    veFlyBalance[msg.sender] += veFlyAmount;
                }
            } else {
                //slither-disable-next-line reentrancy-benign
                Ballot(ballot).unvote(msg.sender, veFlyAmount);
                veFlyBalance[msg.sender] -= veFlyAmount;
            }
        }

        uint256 currentVeShare = _calcVeShare(
            baseShares,
            veFlyBalance[msg.sender]
        );
        veSharesBalance[msg.sender] = currentVeShare;

        unchecked {
            totalVeShare = totalVeShare + currentVeShare - beforeVeShare;
        }
    }

    function vote(uint256 veFlyAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFlyAmount, true);

        if (recount) Ballot(ballot).count();
    }

    function unvote(uint256 veFlyAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFlyAmount, false);

        if (recount) Ballot(ballot).count();
    }

    function forceUnvote(address user) external {
        if (msg.sender != ballot) revert Unauthorized();

        uint256 userVeShares = veSharesBalance[user];
        _updateAccountBonusReward(user, userVeShares);

        totalVeShare -= userVeShares;
        delete veSharesBalance[user];
        delete veFlyBalance[user];
    }

    /*///////////////////////////////////////////////////////////////
                    HELPER GAUGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _updateHopperGaugeFill(uint256 tokenId)
        internal
        returns (uint256 _hopperShare, uint256 _remaining)
    {
        uint256 _generatedPerShareStored = generatedPerShareStored[msg.sender];

        // Resets this hopper generation tracking
        uint256 filledCapPerShare = _generatedPerShareStored -
            tokenCapFilledPerShare[tokenId];

        tokenCapFilledPerShare[tokenId] = _generatedPerShareStored;

        (
            HopperNFT.Hopper memory hopper,
            uint256 prevHopperGauge,
            uint256 gaugeLimit
        ) = _getHopperAndGauge(tokenId);

        _hopperShare = _calculateBaseShare(hopper);

        uint256 flyGeneratedAndBurned = prevHopperGauge +
            filledCapPerShare *
            _hopperShare;

        uint256 currentGauge = flyGeneratedAndBurned > gaugeLimit
            ? gaugeLimit
            : flyGeneratedAndBurned;

        // Update the HOPPER gauge
        HopperNFT(HOPPER).setData(
            LEVEL_GAUGE_KEY,
            tokenId,
            bytes32(currentGauge)
        );

        return (_hopperShare, (gaugeLimit - currentGauge));
    }

    function _getGaugeLimit(uint256 level) internal view returns (uint256) {
        if (level == 1) return 1.5 ether;
        if (level == 100) return 294 ether;
        unchecked {
            return flyLevelCapRatio * _getLevelUpCost(level - 1);
        }
    }

    function _getHopperAndGauge(uint256 _tokenId)
        internal
        view
        returns (
            HopperNFT.Hopper memory,
            uint256, // hopperGauge
            uint256 // gaugeLimit
        )
    {
        string[] memory arrData = new string[](1);
        arrData[0] = LEVEL_GAUGE_KEY;
        (HopperNFT.Hopper memory hopper, bytes32[] memory _data) = HopperNFT(
            HOPPER
        ).getHopperWithData(arrData, _tokenId);

        return (hopper, uint256(_data[0]), _getGaugeLimit(hopper.level));
    }

    function getHopperAndGauge(uint256 tokenId)
        external
        view
        returns (
            HopperNFT.Hopper memory,
            uint256,
            uint256
        )
    {
        return _getHopperAndGauge(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getLevelUpCost(uint256 currentLevel)
        public
        pure
        returns (uint256)
    {
        return _getLevelUpCost(currentLevel);
    }

    /*///////////////////////////////////////////////////////////////
                    ZONE SPECIFIC FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function canEnter(HopperNFT.Hopper memory hopper)
        public
        pure
        virtual
        returns (bool)
    {} // solhint-disable-line

    function _calculateBaseShare(HopperNFT.Hopper memory hopper)
        internal
        pure
        virtual
        returns (uint256)
    {} // solhint-disable-line
}

contract Lake is Zone {
    constructor(
        address fly,
        address vefly,
        address hopper
    ) Zone(fly, vefly, hopper) {}

    // solhint-disable-next-line
    function canEnter(HopperNFT.Hopper memory hopper)
        public
        pure
        override
        returns (bool)
    {
        if (
            hopper.agility < 5 ||
            hopper.vitality < 5 ||
            hopper.intelligence < 5 ||
            hopper.strength < 5 ||
            hopper.level < 20
        ) return false;
        return true;
    }

    function _calculateBaseShare(HopperNFT.Hopper memory hopper)
        internal
        pure
        override
        returns (uint256)
    {
        unchecked {
            return
                uint256(hopper.agility) *
                uint256(hopper.vitality) *
                uint256(hopper.intelligence) *
                uint256(hopper.strength) *
                uint256(hopper.level);
        }
    }
}