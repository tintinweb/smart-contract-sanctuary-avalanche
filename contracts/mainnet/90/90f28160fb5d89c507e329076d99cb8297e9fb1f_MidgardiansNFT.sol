/**
 *Submitted for verification at snowtrace.io on 2022-03-12
*/

/// @author Asgard GameFi - A Metaverse Built for the Gods
/// @notice Midgardian Generation Zero NFT Collection - Midgard is coming

// With love from the Asgard team, see you all in Valhalla!

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

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

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
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

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

  function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
  {
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

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

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
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              owner,
              spender,
              value,
              nonces[owner]++,
              deadline
            )
          )
        )
      );

      address recoveredAddress = ecrecover(digest, v, r, s);

      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "INVALID_SIGNER"
      );

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
      mstore(
        freeMemoryPointer,
        0x23b872dd00000000000000000000000000000000000000000000000000000000
      ) // Begin with the function selector.
      mstore(
        add(freeMemoryPointer, 4),
        and(from, 0xffffffffffffffffffffffffffffffffffffffff)
      ) // Mask and append the "from" argument.
      mstore(
        add(freeMemoryPointer, 36),
        and(to, 0xffffffffffffffffffffffffffffffffffffffff)
      ) // Mask and append the "to" argument.
      mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

      // Call the token and store if it succeeded or not.
      // We use 100 because the calldata length is 4 + 32 * 3.
      callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
    }

    require(
      didLastOptionalReturnCallSucceed(callStatus),
      "TRANSFER_FROM_FAILED"
    );
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
      mstore(
        freeMemoryPointer,
        0xa9059cbb00000000000000000000000000000000000000000000000000000000
      ) // Begin with the function selector.
      mstore(
        add(freeMemoryPointer, 4),
        and(to, 0xffffffffffffffffffffffffffffffffffffffff)
      ) // Mask and append the "to" argument.
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
      mstore(
        freeMemoryPointer,
        0x095ea7b300000000000000000000000000000000000000000000000000000000
      ) // Begin with the function selector.
      mstore(
        add(freeMemoryPointer, 4),
        and(to, 0xffffffffffffffffffffffffffffffffffffffff)
      ) // Mask and append the "to" argument.
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

  function didLastOptionalReturnCallSucceed(bool callStatus)
    private
    pure
    returns (bool success)
  {
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
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    returns (bool)
  {
    return interfaceId == type(IERC165).interfaceId;
  }
}

/*///////////////////////////////////////////////////////////////
                              EIP2981 LOGIC
    //////////////////////////////////////////////////////////////*/

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _value - the sale price of the NFT asset specified by _tokenId
  /// @return _receiver - address of who should be sent the royalty payment
  /// @return _royaltyAmount - the royalty payment amount for value sale price
  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);
}

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC2981Royalties).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
  RoyaltyInfo private _royalties;

  /// @dev Sets token royalties
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function _setRoyalties(address recipient, uint256 value) internal {
    require(value <= 10000, "ERC2981Royalties: Too high");
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  /// @inheritdoc	IERC2981Royalties
  function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (value * royalties.amount) / 10000;
  }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 is ERC2981ContractWideRoyalties {
  /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 indexed id
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

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

    require(
      msg.sender == owner || isApprovedForAll[owner][msg.sender],
      "NOT_AUTHORIZED"
    );

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
      msg.sender == from ||
        msg.sender == getApproved[id] ||
        isApprovedForAll[from][msg.sender],
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

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
      interfaceId == type(IERC2981Royalties).interfaceId; //ERC165 Interface ID for IERC2981Royalties
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
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          ""
        ) ==
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
        ERC721TokenReceiver(to).onERC721Received(
          msg.sender,
          address(0),
          id,
          data
        ) ==
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
} // OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
  function processProof(bytes32[] memory proof, bytes32 leaf)
    internal
    pure
    returns (bytes32)
  {
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

  function _efficientHash(bytes32 a, bytes32 b)
    private
    pure
    returns (bytes32 value)
  {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

/*///////////////////////////////////////////////////////////////
                       CONTRACT OWNERSHIP
    //////////////////////////////////////////////////////////////*/

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
  address internal _owner;
  mapping(address => bool) public allowed;

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
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }
}

//slither-disable-next-line locked-ether
contract MidgardiansNFT is ERC721, Ownable {
  using SafeTransferLib for address;

  receive() external payable {}

  fallback() external payable {}

  /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256[] public MAX_PER_ADDRESS;
  uint256 public MAX_SUPPLY;
  uint256 public PRE_MAX_SUPPLY;
  uint256[] public MINT_COST;

  /*///////////////////////////////////////////////////////////////
                              SALE DETAILS
    //////////////////////////////////////////////////////////////*/

  uint256 public mintTime;
  uint256[] public tierXP = [100 gwei, 200 gwei, 300 gwei];

  /*///////////////////////////////////////////////////////////////
                                MIDGARDIANS
    //////////////////////////////////////////////////////////////*/

  uint256 public midgardiansLength;
  mapping(address => uint256) public minted;
  mapping(uint256 => uint256) public indexer;
  mapping(uint256 => bool) public preminted;

  string public baseURI;
  string public imageURL;
  string public fileFormat;

  /*///////////////////////////////////////////////////////////////
                            MIDGARDIAN NAMES
    //////////////////////////////////////////////////////////////*/

  uint256 public nameFee;
  mapping(bytes32 => bool) public takenNames;
  mapping(uint256 => string) public midgardianNames;

  /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

  event OwnerUpdated(address indexed newOwner);
  event NameChange(uint256 tokenId);
  event UpdatedNameFee(uint256 namefee);

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
  error TooSoon();
  error OnlyAlphanumeric();

  /*///////////////////////////////////////////////////////////////
                PROTOCOL ADDRESSES & CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  IERC20 public volt = IERC20(0xf5ee578505f4D876FeF288DfD9fD5e15e9EA1318);
  IERC20 public wrth = IERC20(0xD1346925E2A09562dF399652a2F4aC38a93404Ee);
  IERC20 public fvor = IERC20(0x9c811efFA8b1Dc7f7590f18e9BeA8F0ebec20Bf4);
  IERC20 public mead = IERC20(0x44a45a9BaEb63c6ea4860ecf9ac5732c330C4d4E);

  constructor() ERC721("Midgardian Generation Zero", "MGZ") {
    MINT_COST = [1.25 ether, 1 ether, 0.75 ether, 0.65 ether];
    MAX_SUPPLY = 10_000;
    MAX_PER_ADDRESS = [8, 15, 20, 25];
    PRE_MAX_SUPPLY = 2_500;

    _setRoyalties(_owner, 400);

    nameFee = 0.25 ether;
    mintTime = 1647126000;
  }

  /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function setNameChangeFee(uint256 _nameFee) external onlyOwner {
    nameFee = _nameFee;
    emit UpdatedNameFee(_nameFee);
  }

  function setMintTime(uint256 _mintTime) external onlyOwner {
    mintTime = _mintTime;
  }

  function setVolt(address _volt) external onlyOwner {
    volt = IERC20(_volt);
  }

  function setMead(address _mead) external onlyOwner {
    mead = IERC20(_mead);
  }

  function setWrth(address _wrth) external onlyOwner {
    wrth = IERC20(_wrth);
  }

  function setFvor(address _fvor) external onlyOwner {
    fvor = IERC20(_fvor);
  }

  function setRoyalties(address _recipient, uint256 _royaltyFee)
    external
    onlyOwner
  {
    _setRoyalties(_recipient, _royaltyFee);
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setFileType(string calldata _fileFormat) external onlyOwner {
    fileFormat = _fileFormat;
  }

  function setImageURL(string calldata _imageURL) external onlyOwner {
    imageURL = _imageURL;
  }

  function withdraw() external onlyOwner {
    _owner.safeTransferETH(address(this).balance);
  }

  /*///////////////////////////////////////////////////////////////
                        MIDGARDIAN LEVELS
    //////////////////////////////////////////////////////////////*/

  function changeMidgardianName(uint256 tokenId, string calldata _newName)
    external
    payable
  {
    require(ownerOf[tokenId] == msg.sender, "Owner must change name of token");
    if (nameFee > msg.value) revert InsufficientAmount();

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
    takenNames[keccak256(bytes(midgardianNames[tokenId]))] = false;

    // Reserve name
    takenNames[nameHash] = true;
    midgardianNames[tokenId] = _newName;

    emit NameChange(tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                          MIDGARDIAN MINTING
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

  function _mintMidgardians(uint256 numberOfMints, uint256 preTotalMidgardians)
    internal
  {
    uint256 seed = enoughRandom();

    uint256 _indexerLength;
    unchecked {
      _indexerLength = MAX_SUPPLY - preTotalMidgardians;
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

      if (block.timestamp < mintTime) preminted[tokenId] = true;

      // Mint Midgardian
      _mint(msg.sender, tokenId);

      unchecked {
        ++i;
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/

  uint256 public reserved = 200;

  function _handleMint(uint256 numberOfMints) internal {
    // solhint-disable-next-line
    if (msg.sender != tx.origin) revert OnlyEOAAllowed();

    unchecked {
      uint256 totalMidgardians = midgardiansLength + numberOfMints;

      if (totalMidgardians > MAX_SUPPLY - reserved)
        revert("Request amount exceeds total mint limits");

      if (block.timestamp < mintTime && totalMidgardians > PRE_MAX_SUPPLY)
        revert("Requested amount exceeds pre-mint limits");

      _mintMidgardians(numberOfMints, totalMidgardians - numberOfMints);
      midgardiansLength = totalMidgardians;
    }
  }

  bool public enabled = false;

  function toggleMint() external onlyOwner {
    enabled = !enabled;
  }

  function reservedMint(uint256 numberOfMints) external onlyOwner {
    uint256 totalMidgardians = midgardiansLength + numberOfMints;
    _mintMidgardians(numberOfMints, totalMidgardians - numberOfMints);
    midgardiansLength = totalMidgardians;
  }

  function uniqueMint(uint256 tokenId) external onlyOwner {
    _mint(msg.sender, tokenId);
  }

  function standardMint(uint256 numberOfMints) external payable {
    require(enabled || msg.sender == _owner, "Minting not enabled");
    require(numberOfMints > 0, "Mint must be non-zero");

    int256 balance = int256(fvor.balanceOf(msg.sender)) -
      int256(wrth.balanceOf(msg.sender));

    uint256 meadbal = mead.balanceOf(msg.sender);

    if (msg.sender != _owner) {
      unchecked {
        if (block.timestamp < mintTime && balance < 100 gwei)
          revert("Public mint is not open yet - 03/12 11PM UTC");
        if (block.timestamp < mintTime - 1 hours)
          revert("Pre-mint is not open yet - 03/12 10PM UTC");
      }
    }

    uint256 maxMint;
    uint256 price;

    if (balance >= int256(tierXP[2])) {
      price = MINT_COST[3];
      maxMint = MAX_PER_ADDRESS[3];
    } else if (balance >= int256(tierXP[1])) {
      price = MINT_COST[2];
      maxMint = MAX_PER_ADDRESS[2];
    } else if (balance >= int256(tierXP[0])) {
      price = MINT_COST[1];
      maxMint = MAX_PER_ADDRESS[1];
    } else {
      price = MINT_COST[0];
      maxMint = MAX_PER_ADDRESS[0];
    }

    if (meadbal >= 1_000_000 gwei) {
      maxMint = maxMint + 5;
    }

    if (price * numberOfMints > msg.value) revert("Insufficient AVAX");
    if (maxMint < numberOfMints + minted[msg.sender])
      revert("Requested amount exceeds wallet mint limits");

    minted[msg.sender] = minted[msg.sender] + numberOfMints;

    volt.transferFrom(msg.sender, _owner, 0.75 gwei * numberOfMints);

    _handleMint(numberOfMints);
  }

  /*///////////////////////////////////////////////////////////////
                        MIDGARDIAN VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  mapping(address => bool) public exchangeAllowed;

  function toggleExchangeAllowed(address _exchange) external onlyOwner {
    exchangeAllowed[_exchange] = !exchangeAllowed[_exchange];
  }

  function exchangeBurn(uint256 tokenId) external {
    require(exchangeAllowed[msg.sender], "Exchange not permitted");
    _burn(tokenId);
  }

  function getMidgardianName(uint256 tokenId)
    public
    view
    returns (string memory name)
  {
    name = midgardianNames[tokenId];

    if (bytes(name).length == 0) {
      name = string(bytes.concat("Midgardian #", bytes(_toString(tokenId))));
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return
      string(
        bytes.concat(
          bytes(baseURI),
          bytes(_toString(tokenId)),
          bytes(fileFormat)
        )
      );
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