/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}
// import {DSTest} from "ds-test/test.sol";


library AliasPacked {
    //8191
    uint16 constant internal PRECISION = 2**13 - 1;
    //Bitmask to set probability to 8191
    bytes3 constant internal PROB_SHIFT = bytes3(uint24(PRECISION) << 11);

    uint constant internal DECIMALS = 1e6;

    //Tried making this more dynamic but wouldn't work as a constant
    //Stores the amount of bytes in a single uint24 
    //1 uint24, max of 0xffffff = 3 bytes
    uint constant internal BYTES_OFFSET = 3;

    function init(uint[] memory weights) internal returns(address) {
        // uint hh = gasleft();
        uint N = weights.length;
        
        //We need to squeeze our alias (index) into 11 bits. So no arrays longer than 2047 thanks
        require(N <= 2047);

        uint avg = uint(PRECISION)*DECIMALS/N;

        //Normalize weights to be (0, PRECISION]
        normalize(weights);

        uint16[] memory small = new uint16[](N);
        uint16[] memory large = new uint16[](N);

        uint smallSize = 0;
        uint largeSize = 0;

        unchecked {
            for (uint16 i = 0; i < N; i++) {
                if (weights[i] < avg)
                    small[smallSize++] = i;
                else
                    large[largeSize++] = i;
            }
        }
    
        bytes memory al = new bytes(N*3);
        
        uint round = N*10;
        unchecked {
            while (smallSize != 0 && largeSize != 0) {
                uint16 less = small[--smallSize];
                uint16 more = large[--largeSize];
                
                uint wLess = weights[less];
                //Round for higher accuracy
                bytes3 toStore = encodeB(uint16(((wLess * round/ DECIMALS)+5)/10), more);
                less = less*3;
                al[less] = bytes1(toStore);
                al[less+1] = bytes1(toStore<<8);
                al[less+2] = bytes1(toStore<<16);

                weights[more] += wLess - avg;
                
                if (weights[more] < avg)
                    small[smallSize++] = more;
                else
                    large[largeSize++] = more;
            }
    
            //set probability to 8191
            while (smallSize != 0) {
                uint16 ind = small[--smallSize]*3;

                al[ind] = bytes1(PROB_SHIFT);
                al[ind+1] = bytes1(PROB_SHIFT<<8);
                al[ind+2] = bytes1(PROB_SHIFT<<16);
            }
                
            //set probability to 8191
            while (largeSize != 0) {
                uint16 ind = large[--largeSize]*3;

                al[ind] = bytes1(PROB_SHIFT);
                al[ind+1] = bytes1(PROB_SHIFT<<8);
                al[ind+2] = bytes1(PROB_SHIFT<<16);
            }
            
        }

        return SSTORE2.write(al);
    }

    function normalize(uint[] memory weights) internal pure {
        uint N = weights.length;
        uint weightSum = 0;
        unchecked {
            for (uint i = 0; i < N; i++) {
                weightSum += weights[i];
            }

            uint norm = uint(PRECISION) * DECIMALS;
            for (uint i = 0; i < N; i++) {
                weights[i] = weights[i] * norm / weightSum;
            }
        }
    }

    function encodeB(uint16 probability, uint16 al) internal pure returns(bytes3 encoded) {
        return bytes3((uint24(probability & 8191) << 11) | uint24(al & 2047));
    }

    function decodeB(bytes3 encoded) internal pure returns(uint16 probability, uint16 al) {
        probability = uint16(uint24(encoded >> 11) & 8191);
        al = uint16(uint24(encoded)) & 2047;
    }

    function pluck(bytes memory b, uint _column) internal pure returns(uint16 probability, uint16 al) {
        uint position = _column * BYTES_OFFSET;
        return decodeB(bytes3(b[position]) | (bytes3(b[position+1])>>8) | bytes3(b[position+2])>>16);
    }

    function getRandomIndex(bytes memory b, uint rand) internal pure returns(uint) {
        //Check this to make sure the rand is at least what we expect it to be
        require(rand > PRECISION);
        //This gets the amount of uint24's stored within the bytes
        //1 uint24 = 3 bytes.
        uint maxColumn = (b.length) / BYTES_OFFSET;
        //we first pick a random column to inspect the probability at
        //TODO: modulo bias... fix or accept it?
        uint column = rand % maxColumn;
        //We pluck the probability and alias out of the column
        (uint16 p, uint16 a) = pluck(b, column);
        //We check if the "decimal" portion of our random number is less than probability
        bool side = rand % PRECISION < p;
        //If it is, we return the column we chose earlier, else we choose the alias at that column
        return side ? column : a;
    }

    function precision() internal pure returns(uint16) {
        return PRECISION;
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

    function ownerOf(uint256 id) public view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view returns (uint256) {
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

error NOT_OWNER();

contract Ownable {
    address public _owner;

    constructor() {
       _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NOT_OWNER();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}
library TestLibrary {
    
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    
}
/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}




contract OneMaskItems is ERC1155 {

    OneMaskNFT public nftContract;

    string public _baseTokenURI;
    
    string[] public layerNames = ["Aura", "Shirt", "Mask"];
    uint constant public TRAIT_COUNT = 3;
    
    //(hash of item values => item id)
    mapping (bytes32 => uint32) internal hashes;
    mapping (uint32 => Item) public items;

    uint32 public tokenIdCounter = 1;
    // mapping (uint256 => uint256) public tokenSupply;
    
    struct Item {
        //2
        uint16 traitTypeIndex;
        //4
        uint16 traitIndex;
    }

    constructor(address _nftContract) {
        nftContract = OneMaskNFT(_nftContract);
    }

    // event MintSet(address indexed to, uint256[] ids);
    // event NewItem(Item item);

    modifier onlyOneMask() {
        require(msg.sender == address(nftContract));
        _;
    }
    /*
    Public Functions
    */

    function setUri(string memory _uri) public onlyOneMask {
        _baseTokenURI = _uri;
    }

    //TODO: add auth to this
    function mintBatch(uint16[] calldata _ids, uint16[] calldata _indices, address to) external {
        require(msg.sender == address(nftContract.packContract()));
        uint len = _indices.length;
        require(len == _ids.length);
        uint32 tokenId = tokenIdCounter;
        unchecked {
            for (uint i; i<len; ++i) {
                uint id = findOrGenItem(_indices[i], _ids[i], tokenId++);
                ++balanceOf[to][id];
            }
        }
        tokenIdCounter = tokenId;
    }

    function findOrGenItem(uint16 layer, uint16 trait, uint32 _tempId) internal returns(uint) {
        bytes32 itemHash = getItemHash(layer, trait);

        uint32 id = hashes[itemHash];

        if (id == 0) {
            genItem(layer, trait, itemHash, _tempId);
            return _tempId;
        }

        return id;
    }

    function genItem(uint16 layer, uint16 trait, bytes32 itemHash, uint32 _tempId) internal {
        //sanity check - not required since only time we use this function we check it
        // require(hashes[itemHash] == 0, "Cannot gen item twice");
        
        Item memory newItem = Item({
            traitTypeIndex: layer,
            traitIndex: trait
        });

        hashes[itemHash] = _tempId;
        items[_tempId] = newItem;
        
        // emit NewItem(newItem);
    }

    function getItemHash(uint16 layer, uint16 trait) internal pure returns(bytes32) {
        return keccak256(abi.encode(layer, trait));
    }


    /*
    View Functions
    */
    
    function getItemFromTrait(uint16 _layer, uint16 _trait) external view returns (Item memory) {
        return items[hashes[getItemHash(_layer, _trait)]];
    }

    function getItem(uint32 itemId) public view returns (Item memory) {
        return items[itemId];
    }

    function getItemsFromIds(uint32[] memory itemIds) public view returns (Item[] memory _items) {
        uint len = itemIds.length;

        for(uint i=0; i<len; i++) {
            _items[i] = items[itemIds[i]];
        }
    }

    function getTokensFromOwner(address _owner) external view returns (uint256[] memory) {
        uint256 maxLen = tokenIdCounter;
        uint256[] memory _items = new uint256[](maxLen);

        for (uint256 i = 1; i < maxLen; i++) {
            if (balanceOf[_owner][i] > 0) _items[i] = i;
        }

        return _items;
    }

    function imgFromId(uint _tokenId) public view returns (string memory) {
        Item memory item = items[uint32(_tokenId)];

        if (item.traitTypeIndex == 0) {
            return "";
        }

        return             
            string(
                abi.encodePacked(
                    "<image width='500' height='500' href='",
                    _baseTokenURI,
                    'layers/',
                    layerNames[item.traitTypeIndex],
                    '/',
                    TestLibrary.toString(item.traitIndex),
                    ".png'/>"
                )
            );
    }

    function svgFromId(uint _tokenId) public view returns(string memory) {
        require(items[uint32(_tokenId)].traitTypeIndex != 0, "Does not exist");
        
        return             
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg'>",  
                    imgFromId(_tokenId),
                    '</svg>'
                )
            );
    }

    function uri(uint _tokenId) public view override returns (string memory) {
        require(items[uint32(_tokenId)].traitTypeIndex != 0, "Does not exist");
        
        return 
            string(
                abi.encodePacked(
                    '{"name": "Item #',
                    TestLibrary.toString(_tokenId),
                    '", "id": "',
                    TestLibrary.toString(_tokenId),
                    '", "image": "',
                    svgFromId(_tokenId),
                    '"}'
                )
            );
    }

}


contract OneMaskNFT is ERC721, Ownable, RolesAuthority {
    
    string public _baseTokenURI;
    OneMaskItems public itemContract;
    Pack public packContract;

    uint constant private TRAIT_COUNT = 3;

    string[7] private layerNames = ["Background", "Shadow", "Aura", "Base", "Shirt", "Head", "Mask"];
    //0 = default layer, non-zero points to the one-indexed index of its layer
    uint8[7] private DEFAULT_LAYERS = [0, 0, 1, 0, 2, 0, 3];

    mapping (uint256 => Blue) private blues;

    uint public totalSupply;
    
    struct Blue {
        uint48 items;
    }

    constructor(
        address owner,
        address authorizedMinter
    ) ERC721("OneMask", "BLUE") RolesAuthority(owner, Authority(address(this))) {
        uint16[TRAIT_COUNT] memory _maxIds = [uint16(5), 14, 15];
        address[TRAIT_COUNT] memory _aliasPointers;

        for (uint j = 0; j < TRAIT_COUNT; j++) {
            uint16 len = _maxIds[j];
            uint[] memory _weights = new uint[](len);

            for(uint i = 0; i < len; i++) {
                uint r = i+1;
                _weights[i] = r;
            }
            _aliasPointers[j] = AliasPacked.init(_weights);
        }

        packContract = new Pack(_aliasPointers, address(this));

        //Role 0 = minter
        getUserRoles[authorizedMinter] = bytes32(uint(1));
        getRolesWithCapability[address(this)][0x40c10f19] |= bytes32(uint(1));
    }

    event Unequip(uint256 tokenId, uint256 itemId);
    event Equip  (uint256 tokenId, uint256 itemId);
    
    /**
      * @dev Mints Blues with random items
      * @param amnt Amount to mint
      */
    function mint(
        address to,
        uint256 amnt
    ) public requiresAuth {
        require(amnt <= 255, "MINT_AMNT_GT_255");

        uint256 id = totalSupply;
        //iterators cannot overflow, id overflowing is unrealistic, balanceOf overflowing is equally unrealistic
        unchecked {
            for (uint i; i < amnt; ++i) {
                //replaces _mint(msg.sender, id)
                _ownerOf[id] = to;
                
                id++;
            }
            totalSupply = id;
            _balanceOf[to] += amnt;
        }

        packContract.packsPurchase(uint8(amnt), to);
    }

    /// @dev wrapper for mint(address,uint)
    function mint(uint256 amnt) external requiresAuth { 
        mint(msg.sender, amnt); 
    }

    /**
      * @dev Unequips an item from a Blue and sends it to the caller
      * @param tokenId Blue id to unequip from. caller must be approved or owner
      * @param itemId Item id to unequip
      */
    function unequipItem(
        uint256 tokenId, 
        uint16 itemId
    ) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "not owner nor approved");

        uint16 _traitTypeIndex = itemContract.getItem(itemId).traitTypeIndex;
        uint48 currentItems = blues[tokenId].items;
        uint16 currentItem = getBluesItem(currentItems, _traitTypeIndex);

        require(currentItem != 0, "Already unequipped");
        require(currentItem == itemId, "Blue does not have this item");

        //First remove the item from the blue
        blues[tokenId].items = setBluesItem(currentItems, _traitTypeIndex, itemId);
        //Then transfer one item from this contract to the blue owner
        itemContract.safeTransferFrom(address(this), msg.sender, itemId, 1, "");

        emit Unequip(tokenId, itemId);
    }

    /**
      * @dev Equips an item to a Blue from the caller's wallet
      * @param tokenId Blue id to equip to. Caller must be approved or owner
      * @param itemId Item id to equip, must own item
      */
    function equipItem(
        uint256 tokenId,
        uint16 itemId
    ) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "not owner nor approved");
        require(itemContract.balanceOf(msg.sender, itemId) > 0, "Does not own requested item");
        
        uint16 _traitTypeIndex = itemContract.getItem(itemId).traitTypeIndex;
        uint48 currentItems = blues[tokenId].items;
        uint16 currentItem = getBluesItem(currentItems, _traitTypeIndex);

        require(currentItem == 0, "Slot already has item");
        //Add the item to the blue
        blues[tokenId].items = setBluesItem(currentItems, _traitTypeIndex, 0);
        //Then transfer it from the caller to this contract
        itemContract.safeTransferFrom(msg.sender, address(this), itemId, 1, "");

        emit Equip(tokenId, itemId);
    }

    function isItemEquipped(
        uint256 tokenId,
        uint16 itemId
    ) public view returns(bool) {
        uint16 traitTypeIndex = itemContract.getItem(itemId).traitTypeIndex;
        uint48 currentItems = blues[tokenId].items;

        return getBluesItem(currentItems, traitTypeIndex) != 0;
    }

    //TODO: maybe make clearBluesItem to get rid of and()
    function setBluesItem(
        uint48 blueItems,
        uint16 itemLayer,
        uint16 itemId
    ) internal pure returns(uint48) {
        uint48 mask;
        assembly {
            let itemShift := mul(itemLayer, 16)
            mask := not(shl(itemShift, 0xFFFF))
            mask := and(shl(itemShift, itemId), mask)
        }
        // uint48 mask = ~(0xFFFF << (uint48(itemLayer) * 16)) & (itemId << (itemLayer * 16));
        return blueItems &= mask;
    }

    function getBluesItem(
        uint48 blueItems,
        uint16 itemLayer
    ) internal pure returns(uint16 item) {
        assembly {
            item := shl(mul(itemLayer, 16), blueItems)
        }
    }


    function isApprovedOrOwner(
        address spender, 
        uint256 id
    ) internal view returns(bool) {
        return msg.sender == spender || msg.sender == getApproved[id] || isApprovedForAll[spender][msg.sender];
    }

    /// @notice Batch get owners from ids
    function ownersOf(
        uint[] calldata ids
    ) external view returns(address[] memory _owners) {
        uint n = ids.length;
        _owners = new address[](n);
        for (uint i = 0; i<n; i++) {
            _owners[i] = _ownerOf[ids[i]];
        }
    }

    /**
      * @dev returns items equipped on the blue
      */
    function blueFromId(
        uint256 id
    ) external view returns(Blue memory) {
        return blues[id];
    }

    /**
      * @dev returns Blue[] from inputted ids
      * @param ids array of blue ids
      */
    function bluesFromIds(
        uint256[] calldata ids
    ) external view returns(Blue[] memory bluesData) {
        uint len = ids.length;
        bluesData = new Blue[](len);
        for(uint i=0;i<len;i++) {
            bluesData[i] = blues[ids[i]];
        }
    }
    
    /**
      * @dev gets list of tokenIds that _address owns
      */
    function getTokensFromOwner(
        address _address
    ) external view returns(uint256[] memory) { unchecked {
        uint256 balance = _balanceOf[_address];
        uint256[] memory tokens = new uint256[](balance);
        
        uint256 currentId = totalSupply;
        uint256 found = 0;
        
        for (uint i = 0; i < currentId; i++) {
            if (_ownerOf[i] == _address) {
                tokens[found] = i;
                if (found++ >= balance) break;
            }
        }
        
        return tokens;
    }}

    //Public
    
    function attributesFromId(
        uint256 tokenId
    ) public view returns (string memory) {
        
        string memory attrString;
        uint48 bluesItems = blues[tokenId].items;

        uint16 found = 0;
        for (uint i = 0; i < layerNames.length; i++) {
            if (DEFAULT_LAYERS[i] == 0) continue;
            attrString = string(
                abi.encodePacked(
                    attrString,
                    '{"trait_type":"',
                    layerNames[i],
                    '","value":"',
                    TestLibrary.toString(getBluesItem(bluesItems, found++)),
                    '"}'
                )
            );
            if (found != TRAIT_COUNT)
                attrString = string(abi.encodePacked(attrString, ","));
        }

        return string(abi.encodePacked("[", attrString, "]"));
        
    }
    
    function svgFromId(
        uint256 _tokenId
    ) public view returns(string memory) {

        string memory svgString;
        uint48 bluesItems = blues[_tokenId].items;

        uint16 found = 0;
        for (uint i = 0; i < layerNames.length; i++) {
            if (DEFAULT_LAYERS[i] == 0) {
                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<image width='500' height='500' href='",
                        _baseTokenURI,
                        'layers/',
                        layerNames[i],
                        '/',
                        '1',
                        ".png'/>"
                    )
                );
            } else {
                svgString = string(
                    abi.encodePacked(
                        svgString,
                        itemContract.imgFromId(getBluesItem(bluesItems, found++))
                    )
                );
            }

        }

        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg'>", svgString, '</svg>'));
    }
    
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_ownerOf[_tokenId] != address(0), "tokenURI: does not exist");
        
        return 
            string(
                abi.encodePacked(
                    '{"name": "Blue #',
                    TestLibrary.toString(_tokenId),
                    '", "id": "',
                    TestLibrary.toString(_tokenId),
                    '", "image": "',
                    svgFromId(_tokenId),
                    '","attributes":',
                    attributesFromId(_tokenId),
                    "}"
                )
            );
    }

    /*
        Owner Functions
    */

    function setItemContract(
        address _itemContract
    ) public onlyOwner {
        require(address(itemContract) == address(0));
        itemContract = OneMaskItems(_itemContract);
        setBaseURI("https://arweave.net/UdIDbE6z4p9ZyUhmR-qRihQiOW7MjJKnlvjE0etYHt4/");
    }

    function setBaseURI(
        string memory baseURI
    ) public onlyOwner {
        _baseTokenURI = baseURI;
        itemContract.setUri(baseURI);
    }
    




    
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }
}

contract Pack {

    uint constant public ITEMS_PER_PACK = 3;

    OneMaskNFT immutable public nftContract;
    address[ITEMS_PER_PACK] public aliasPointers;
    
    mapping (uint => PackPurchase) public purchases;

    uint24 public totalSupply;
    uint24 public lastRevealUpdate;

    struct PackPurchase {
        //3 - 16 million ids
        uint24 id;
        //4 - 255 max packs
        uint8 count;
        //8 - 270+ years of blocks on avalanche
        uint32 commitBlock;
        //12 - much more random bits than we need (absolute minimum of 13)
        uint32 randomness;
        //32
        address owner;
    }

    constructor(
        address[ITEMS_PER_PACK] memory _aliasPointers,
        address _oneMaskNft
    ) {
        nftContract = OneMaskNFT(_oneMaskNft);
        aliasPointers = _aliasPointers;
    }

    event RandomnessRevealed(address indexed revealer, uint packId, uint randomness);
    event ClaimedItems(address indexed to, uint16[] itemLayers, uint16[] itemIndices);
    event Recommit(uint32 packId);

    function packsPurchase(
        uint8 amount, 
        address to
    ) external {
        require(msg.sender == address(nftContract));
        uint24 id = totalSupply++;

        purchases[id] = PackPurchase(id, amount, uint32(block.number + 1), 0, to);
    }

    function revealAllPurchases(
        uint24 _lastRevealUpdate, 
        uint24 maxToReveal
    ) external {
        //We do this so if several users submit a reveal tx at the same time only the first will pass the current lastRevealUpdate
        require(_lastRevealUpdate == lastRevealUpdate, "INCORRECT_LAST_REVEAL");

        //TODO: make sure totalsupply can't be manipulated
        uint24 _totalSupply = totalSupply;
        
        //To prevent DOS, we take in the desired amount the user wants to reveal.
        uint24 revealUpTo = _lastRevealUpdate + maxToReveal;
        revealUpTo = revealUpTo >= _totalSupply ? _totalSupply : revealUpTo;

        for (uint i = _lastRevealUpdate; i < revealUpTo; i++) {
            //Saves a warm SLOAD :)
            revealPurchase(i);
        }

        //We can be certain that all unrevealed packs up to revealUpTo have been revealed
        lastRevealUpdate = revealUpTo;
    }

    //We don't check last reveal update since we revert if the pack has already been revealed vs continuing the loop
    function revealPurchase(
        uint id
    ) public {
        PackPurchase storage p = purchases[id];
        //Pack Randomness must not be revealed yet
        //We don't revert because this is used in the loop case as well
        if(p.randomness != 0) return;

        revealPurchase(p);
    }

    //Internal reveal case used by revealPurchase(uint) and claimPacks
    function revealPurchase(
        PackPurchase storage p
    ) internal {
        uint id = p.id;
        uint64 commitBlock = p.commitBlock;

        require(block.number < commitBlock + 256, "TOO_LATE_REVEAL");
        require(block.number > commitBlock, "TOO_EARLY_REVEAL");

        bytes32 commitHash = blockhash(commitBlock);

        //Last sanity check to make sure we're in the blockhash range
        require(commitHash != 0, "Sanity Check");

        //commit hash and id can't be changed after commit, outside of block producer of commitBlock
        //Without id, 2 packs revealed in the same block would have same randomness.
        uint32 random = uint32(uint(keccak256(abi.encodePacked(commitHash, id))));

        p.randomness = random;

        emit RandomnessRevealed(msg.sender, id, random);
    }

    function claimPurchase(
        uint id
    ) external {
        PackPurchase storage p = purchases[id];
        require(p.owner == msg.sender);
        uint8 packsInPurchase = p.count;
        uint16[] memory _items = new uint16[](packsInPurchase * ITEMS_PER_PACK);
        uint16[] memory _itemLayers = new uint16[](packsInPurchase * ITEMS_PER_PACK);

        bytes[ITEMS_PER_PACK] memory aliasPointersBytes = getAliasPointersBytes();

        uint64 commitBlock = p.commitBlock;

        //If the pack is revealable then do it
        if (p.randomness == 0 && block.number > commitBlock && block.number < commitBlock + 256)
            revealPurchase(p);
        
        uint32 randomness = p.randomness;
        require(randomness != 0, "Pack Not Revealed");

        for (uint k = 0; k < packsInPurchase; k++) {
            for (uint j = 0; j < ITEMS_PER_PACK; j++) {
                //Seed 112233 just for testing distribution
                uint random = uint(keccak256(abi.encode(j, randomness, k, 0x112233)));
                
                uint indexToSet = j + k*ITEMS_PER_PACK;
                _items[indexToSet] = uint16(AliasPacked.getRandomIndex(aliasPointersBytes[j], random));
                _itemLayers[indexToSet] = uint16(j);
            }
        }

        delete purchases[id];
        
        nftContract.itemContract().mintBatch(_items, _itemLayers, msg.sender);
    }

    /// @notice Used if the purchase was not revealed within the 255 block window
    ///         Opens some potential attack vectors but not concerned
    function recommitPurchase(
        uint id
    ) external {
        PackPurchase storage p = purchases[id];

        require(p.randomness == 0);
        require(block.number >= p.commitBlock + 256);

        p.commitBlock = uint32(block.number + 1);

        emit Recommit(uint32(id));
    }

    function predictPurchase(
        uint id
    ) external view returns(uint16[] memory _items, uint16[] memory _itemLayers) {
        PackPurchase memory p = purchases[id];
        
        if (p.randomness == 0 && block.number > p.commitBlock && block.number < p.commitBlock + 256) {
            p.randomness = uint32(uint(keccak256(abi.encodePacked(blockhash(p.commitBlock), id))));
        }
        require(p.randomness != 0, "Pack Not Revealed");

        uint8 packsInPurchase = p.count;
        _items = new uint16[](packsInPurchase * ITEMS_PER_PACK);
        _itemLayers = new uint16[](packsInPurchase * ITEMS_PER_PACK);

        bytes[ITEMS_PER_PACK] memory aliasPointersBytes = getAliasPointersBytes();

        for (uint k = 0; k < packsInPurchase; k++) {
            for (uint j = 0; j < ITEMS_PER_PACK; j++) {
                //Seed 112233 just for testing distribution
                uint random = uint(keccak256(abi.encode(j, p.randomness, k, 0x112233)));
                
                uint indexToSet = j + k*ITEMS_PER_PACK;
                _items[indexToSet] = uint16(AliasPacked.getRandomIndex(aliasPointersBytes[j], random));
                _itemLayers[indexToSet] = uint16(j);
            }
        }
    }

    function getAliasPointersBytes(

    ) internal view returns(bytes[ITEMS_PER_PACK] memory aliasPointersBytes) {
        address[ITEMS_PER_PACK] memory _aliasPointers = aliasPointers;
        for (uint i = 0; i < ITEMS_PER_PACK; i++)
            aliasPointersBytes[i] = SSTORE2.read(_aliasPointers[i]);
    }

    function getUnrevealedPurchasesAmount(

    ) external view returns(uint amount) {
        uint _totalSupply = totalSupply;

        for (uint i = 0; i < _totalSupply; i++) {
            PackPurchase memory p = purchases[i];
            //Pack Randomness must not be revealed yet
            if (p.commitBlock == 0) continue;
            if (p.randomness != 0) continue;
            amount++;
        }
    }

    function getPurchase(
        uint id
    ) public view returns(PackPurchase memory) {
        return purchases[id];
    }

    function getPurchasesByOwner(
        address _owner
    ) external view returns(PackPurchase[] memory _purchases) {
        _purchases = new PackPurchase[](totalSupply);
        uint found = 0;
        for (uint i = 0; i < totalSupply; ++i) {
            PackPurchase memory p = purchases[i];
            if (p.owner == _owner) _purchases[found++] = p;
        }
    }

}