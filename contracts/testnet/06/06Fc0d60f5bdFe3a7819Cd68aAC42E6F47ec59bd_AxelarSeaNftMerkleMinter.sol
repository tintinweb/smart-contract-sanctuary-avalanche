//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/MerkleProof.sol";
import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaNftBase.sol";
// import "hardhat/console.sol";

contract AxelarSeaNftMerkleMinter is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct AxelarSeaNftMintData {
    bytes32 merkleRoot;
    uint256 mintPriceStart;
    uint256 mintPriceEnd;
    uint256 mintPriceStep;
    uint256 mintStart;
    uint256 mintEnd;
    IERC20 mintTokenAddress;
  }

  bool private initialized;
  AxelarSeaProjectRegistry public registry;
  AxelarSeaNftMintData public mintData;
  AxelarSeaNftBase public nft;

  event UpdateConfigMerkleMinter(
    address indexed nftAddress,
    bytes32 indexed collectionId,
    bytes32 indexed projectId,
    AxelarSeaNftMintData mintData
  );
  function _updateConfig(
    bytes memory data
  ) internal {
    mintData = abi.decode(data, (AxelarSeaNftMintData));

    require(mintData.mintEnd >= mintData.mintStart, "Invalid timestamp");

    emit UpdateConfigMerkleMinter(
      address(nft),
      nft.collectionId(),
      nft.projectId(),
      mintData
    );
  }

  function updateConfig(
    bytes memory data
  ) public onlyOwner {
    _updateConfig(data);
  }

  function initialize(
    address targetNft,
    address owner,
    bytes memory data
  ) external {
    require(!initialized, "Initialized");
    initialized = true;

    nft = AxelarSeaNftBase(targetNft);
    registry = nft.registry();

    _updateConfig(data);
    _transferOwnership(owner);
  }

  function mintFee() public view returns(uint256) {
    return nft.mintFee();
  }

  function mintPrice() public view returns(uint256) {
    unchecked {
      if (mintData.mintPriceStep == 0) {
        return mintData.mintPriceStart;
      }

      if (block.timestamp < mintData.mintStart) {
        return mintData.mintPriceStart;
      }
      
      // block.timestamp >= mintStart
      uint256 priceChange = mintData.mintPriceStep * (block.timestamp - mintData.mintStart);
      uint256 priceDiff = mintData.mintPriceEnd <= mintData.mintPriceStart ? mintData.mintPriceStart - mintData.mintPriceEnd : mintData.mintPriceEnd - mintData.mintPriceStart;

      if (priceChange < priceDiff) {
        return mintData.mintPriceEnd <= mintData.mintPriceStart ? mintData.mintPriceStart - priceChange : mintData.mintPriceStart + priceChange; 
      } else {
        return mintData.mintPriceEnd;
      }
    }
  }

  function _pay(address from, uint256 amount) internal {
    if (block.timestamp < mintData.mintStart || block.timestamp > mintData.mintEnd) {
      revert NotMintingTime();
    }

    if (mintData.mintPriceStart > 0 || mintData.mintPriceEnd > 0) {
      uint256 totalPrice = mintPrice() * amount;
      uint256 fee = totalPrice * mintFee() / 1e18;

      // console.log(totalPrice);

      mintData.mintTokenAddress.safeTransferFrom(from, registry.feeAddress(), fee);
      mintData.mintTokenAddress.safeTransferFrom(from, nft.fundAddress(), totalPrice - fee);
    }
  }

  function checkMerkle(address toCheck, uint256 maxAmount, bytes32[] calldata proof) public view returns(bool) {
    return MerkleProof.verify(proof, mintData.merkleRoot, keccak256(abi.encodePacked(toCheck, maxAmount)));
  }

  function mintMerkle(address to, uint256 maxAmount, uint256 amount, bytes32[] calldata proof) public nonReentrant {
    require(checkMerkle(to, maxAmount, proof), "Not whitelisted");
    _pay(msg.sender, amount);
    nft.mint(to, maxAmount, amount);
  }

  // function mintSignature(
  //   address operatorAddress,
  //   uint256 nonce,
  //   bytes32 sigR,
  //   bytes32 sigS,
  //   uint8 sigV,
  //   bytes memory payload
  // ) public onlyMinter(operatorAddress) nonReentrant {
  //   verifyMetaTransaction(
  //     operatorAddress,
  //     payload,
  //     nonce,
  //     sigR,
  //     sigS,
  //     sigV
  //   );

  //   (address to, uint256 maxAmount, uint256 amount) = abi.decode(payload, (address, uint256, uint256));
  //   _pay(msg.sender, amount);
  //   _mintInternal(to, maxAmount, amount);
  // }

  function recoverETH() external onlyOwner {
    payable(msg.sender).call{value: address(this).balance}("");
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProof.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProof {
  function verify(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool isValid) {
    assembly {
      let computedHash := leaf

      // Initialize `data` to the offset of `proof` in the calldata.
      let data := proof.offset

      // Iterate over proof elements to compute root hash.
      for {
        // Left shift by 5 is equivalent to multiplying by 0x20.
        let end := add(data, shl(5, proof.length))
      } lt(data, end) {
        data := add(data, 0x20)
      } {
        let loadedData := calldataload(data)
        // Slot of `computedHash` in scratch space.
        // If the condition is true: 0x20, otherwise: 0x00.
        let scratch := shl(5, gt(computedHash, loadedData))

        // Store elements to hash contiguously in scratch space.
        // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
        mstore(scratch, computedHash)
        mstore(xor(scratch, 0x20), loadedData)
        computedHash := keccak256(0x00, 0x40)
      }
      isValid := eq(computedHash, root)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EIP712Base} from "./EIP712Base.sol";

contract MetaTransactionVerifier is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(uint256 => bool) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function verifyMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        uint256 nonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal {
        require(!nonces[nonce], "Already run");

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonce,
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            _verifyMetaTransaction(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // mark nonce to prevent tx reuse
        nonces[nonce] = true;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function _verifyMetaTransaction(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

//SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

interface IAxelarSeaNftInitializable {
  function initialize(
    address owner,
    bytes32 collectionId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name, 
    string memory symbol
  ) external;

  function deployMinter(
    address template,
    bytes memory data
  ) external returns(IAxelarSeaMinterInitializable minter);

  function mint(address to, uint256 maxAmount, uint256 amount) external;
}

interface IAxelarSeaMinterInitializable {
  function initialize(
    address targetNft,
    address owner,
    bytes memory data
  ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../meta-transactions/MetaTransactionVerifier.sol";
import "./IAxelarSeaNftInitializable.sol";
import "./AxelarSeaProjectRegistry.sol";

import "./AxelarSeaMintingErrors.sol";

abstract contract AxelarSeaNftBase is Ownable, MetaTransactionVerifier, IAxelarSeaNftInitializable, ReentrancyGuard {
  using Strings for uint256;
  using SafeERC20 for IERC20;

  bool private initialized;

  bool public newMinterStopped = false;

  AxelarSeaProjectRegistry public registry;
  address public fundAddress;

  bytes32 public collectionId;
  string private nftName;
  string private nftSymbol;
  uint256 public exclusiveLevel;
  uint256 public maxSupply;

  mapping(address => bool) public exclusiveContract;
  mapping(address => bool) public minters;
  mapping(address => uint256) public walletMinted;

  uint256 public mintFeeOverride = 0;
  bool public enableMintFeeOverride = false;

  string public baseTokenUriPrefix = "";
  string public baseTokenUriSuffix = "";

  modifier onlyMinter(address addr) {
    require(minters[addr], "Forbidden");
    _;
  }

  constructor() {}

  function initialize(
    address owner,
    bytes32 _collectionId,
    uint256 _exclusiveLevel,
    uint256 _maxSupply,
    string memory _nftName,
    string memory _nftSymbol
  ) public {
    require(!initialized, "Initialized");

    initialized = true;
    registry = AxelarSeaProjectRegistry(msg.sender);
    collectionId = _collectionId;
    exclusiveLevel = _exclusiveLevel;
    maxSupply = _maxSupply;
    nftName = _nftName;
    nftSymbol = _nftSymbol;

    fundAddress = owner;

    _transferOwnership(owner);
  }

  event StopNewMinter();
  function stopNewMinter() public onlyOwner {
    newMinterStopped = true;
    emit StopNewMinter();
  }

  event SetMaxSupply(uint256 supply);
  function setMaxSupply(uint256 newSupply) public onlyOwner {
    if (newMinterStopped) {
      revert Forbidden();
    }

    maxSupply = newSupply;
    emit SetMaxSupply(newSupply);
  }

  event SetMinter(address indexed minter, bool enabled);
  function setMinter(address minter, bool enabled) public onlyOwner {
    if (newMinterStopped) {
      revert Forbidden();
    }

    minters[minter] = enabled;
    emit SetMinter(minter, enabled);
  }

  function deployMinter(address template, bytes memory data) public nonReentrant returns(IAxelarSeaMinterInitializable minter) {
    if (msg.sender != owner() && msg.sender != address(registry)) {
      revert Forbidden();
    }

    if (!registry.minterTemplates(template)) {
      revert InvalidTemplate(template);
    }

    minter = IAxelarSeaMinterInitializable(Clones.clone(template));
    minter.initialize(address(this), owner(), data);

    minters[address(minter)] = true;
    emit SetMinter(address(minter), true);
  }

  event SetExclusiveContract(address indexed addr, bool enabled);
  function setExclusiveContract(address addr, bool enabled) public {
    if (msg.sender != owner() && !registry.operators(msg.sender)) {
      revert Forbidden();
    }

    exclusiveContract[addr] = enabled;
    emit SetExclusiveContract(addr, enabled);
  }

  event OverrideMintFee(address indexed overrider, uint256 newFee, bool overrided);
  function overrideMintFee(uint256 newFee, bool overrided) public {
    if (!registry.operators(msg.sender)) {
      revert Forbidden();
    }

    enableMintFeeOverride = overrided;
    mintFeeOverride = newFee;
    emit OverrideMintFee(msg.sender, newFee, overrided);
  }

  function _beforeTokenTransferCheck(address from) internal view {
    if (from != address(0)) {
      require(exclusiveLevel < 2, "Soulbound");
      require(exclusiveLevel < 1 || registry.axelarSeaContract(msg.sender) || exclusiveContract[msg.sender], "Forbidden");
    }
  }

  function _mintInternal(address to, uint256 maxAmount, uint256 amount) internal virtual;

  function mintFee() public view returns(uint256) {
    return (enableMintFeeOverride ? mintFeeOverride : registry.baseMintFee());
  }

  function mint(address to, uint256 maxAmount, uint256 amount) public onlyMinter(msg.sender) nonReentrant {
    _mintInternal(to, maxAmount, amount);
  }

  function setBaseTokenUriPrefix(string memory newPrefix) public onlyOwner {
    baseTokenUriPrefix = newPrefix;
  }

  function setBaseTokenUriSuffix(string memory newSuffix) public onlyOwner {
    baseTokenUriSuffix = newSuffix;
  }

  function recoverETH() external onlyOwner {
    payable(msg.sender).call{value: address(this).balance}("");
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  function exists(uint256 tokenId) public virtual view returns(bool);

  function projectId() public view returns(bytes32) {
    return registry.nftProject(address(this));
  }

  // Opensea standard contractURI
  function contractURI() external view returns (string memory) {
    return string(abi.encodePacked(registry.baseContractURI(), uint256(collectionId).toHexString()));
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (bytes(baseTokenUriPrefix).length == 0) {
      return string(abi.encodePacked(registry.baseTokenURI(), uint256(collectionId).toHexString(), "/", tokenId.toString()));
    } else {
      return string(abi.encodePacked(baseTokenUriPrefix, tokenId.toString(), baseTokenUriSuffix));
    }
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view virtual returns (string memory) {
      return nftName;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view virtual returns (string memory) {
      return nftSymbol;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                getChainId(),
                address(this)
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: BUSL
pragma solidity ^0.8.0;

import "./IAxelarSeaNftInitializable.sol";
import "../meta-transactions/NativeMetaTransaction.sol";
import "../meta-transactions/ContextMixin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AxelarSeaMintingErrors.sol";

contract AxelarSeaProjectRegistry is Ownable, NativeMetaTransaction, ContextMixin, ReentrancyGuard {
  using SafeERC20 for IERC20;

  mapping(address => bool) public operators;
  mapping(address => bool) public templates;
  mapping(address => bool) public minterTemplates;
  mapping(address => bool) public axelarSeaContract;

  mapping(bytes32 => address) public projectOwner;
  mapping(address => bytes32) public nftProject;

  // 1 = Member, 2 = Admin
  mapping(bytes32 => mapping(address => uint256)) public projectMember;

  // Minting fee
  address public feeAddress;
  uint256 public baseMintFee = 0.02 ether;

  string public baseContractURI = "https://api-nftdrop.axelarsea.com/contractMetadata/";
  string public baseTokenURI = "https://api-nftdrop.axelarsea.com/tokenMetadata/";

  constructor() {
    feeAddress = msg.sender;
  }

  modifier onlyOperator {
    require(operators[msgSender()], "Not Operator");
    _;
  }

  event SetMintFee(address indexed addr, uint256 fee);
  function setMintFee(address addr, uint256 fee) public onlyOwner {
    require(fee <= 1 ether, "Too much fee");
    feeAddress = addr;
    baseMintFee = fee;
    emit SetMintFee(addr, fee);
  }

  event SetOperator(address indexed operator, bool enabled);
  function setOperator(address operator, bool enabled) public onlyOwner {
    operators[operator] = enabled;
    emit SetOperator(operator, enabled);
  }

  event SetMinterTemplate(address indexed template, bool enabled);
  function setMinterTemplate(address template, bool enabled) public onlyOwner {
    minterTemplates[template] = enabled;
    emit SetMinterTemplate(template, enabled);
  }

  event SetTemplate(address indexed template, bool enabled);
  function setTemplate(address template, bool enabled) public onlyOwner {
    templates[template] = enabled;
    emit SetTemplate(template, enabled);
  }

  event SetAxelarSeaContract(address indexed addr, bool enabled);
  function setAxelarSeaContract(address addr, bool enabled) public onlyOwner {
    axelarSeaContract[addr] = enabled;
    emit SetAxelarSeaContract(addr, enabled);
  }

  event NewProject(address indexed owner, bytes32 projectId);
  function newProject(address owner, bytes32 projectId) public onlyOperator {
    projectOwner[projectId] = owner;
    projectMember[projectId][owner] = 2;

    emit NewProject(owner, projectId);
  }

  event SetProjectMember(bytes32 indexed projectId, address indexed member, uint256 level);
  function setProjectMember(bytes32 projectId, address member, uint256 level) public {
    require(level <= 2 && projectMember[projectId][msgSender()] == 2 && member != projectOwner[projectId] && projectOwner[projectId] != address(0), "Forbidden");
    projectMember[projectId][member] = level;
    emit SetProjectMember(projectId, member, level);
  }

  event SetProjectOwner(bytes32 indexed projectId, address indexed owner);
  function setProjectOwner(bytes32 projectId, address owner) public {
    require(msgSender() == projectOwner[projectId] && projectMember[projectId][owner] == 2 && projectOwner[projectId] != address(0), "Forbidden");
    projectOwner[projectId] = owner;
    emit SetProjectOwner(projectId, owner);
  }

  // Only linkable if that NFT implement Ownable
  event LinkProject(address indexed contractAddress, bytes32 projectId);
  function _linkProject(address contractAddress, bytes32 projectId) internal {
    address owner = Ownable(contractAddress).owner();

    require(owner != address(0) && owner == projectOwner[projectId], "Not owner");

    nftProject[contractAddress] = projectId;

    emit LinkProject(contractAddress, projectId);
  }

  function linkProject(address contractAddress, bytes32 projectId) public nonReentrant {
    // Check support interface
    require(IERC165(contractAddress).supportsInterface(0x80ac58cd) || IERC165(contractAddress).supportsInterface(0xd9b67a26), "Not NFT");

    _linkProject(contractAddress, projectId);
  }

  event DeployNft(address indexed template, address indexed owner, address indexed contractAddress, bytes32 collectionId, bytes32 projectId);
  function deployNft(
    address template,
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name,
    string memory symbol
  ) public nonReentrant returns(IAxelarSeaNftInitializable nft) {
    if (!templates[template]) {
      revert InvalidTemplate(template);
    }

    nft = IAxelarSeaNftInitializable(Clones.clone(template));
    nft.initialize(owner, collectionId, exclusiveLevel, maxSupply, name, symbol);
    _linkProject(address(nft), projectId);
    emit DeployNft(template, owner, address(nft), collectionId, projectId);
  }

  function deployNftWithMinter(
    address template,
    address minterTemplate,
    address owner,
    bytes32 collectionId,
    bytes32 projectId,
    uint256 exclusiveLevel,
    uint256 maxSupply,
    string memory name,
    string memory symbol,
    bytes memory data
  ) public nonReentrant returns(IAxelarSeaNftInitializable nft, IAxelarSeaMinterInitializable minter) {
    if (!templates[template]) {
      revert InvalidTemplate(template);
    }

    if (!minterTemplates[minterTemplate]) {
      revert InvalidTemplate(minterTemplate);
    }

    nft = IAxelarSeaNftInitializable(Clones.clone(template));
    nft.initialize(owner, collectionId, exclusiveLevel, maxSupply, name, symbol);
    _linkProject(address(nft), projectId);

    minter = nft.deployMinter(minterTemplate, data);

    emit DeployNft(template, owner, address(nft), collectionId, projectId);
  }

  function setBaseContractURI(string memory _uri) public onlyOwner {
    baseContractURI = _uri;
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    baseTokenURI = _uri;
  }
}

//SPDX-License-Identifier: BUSL
pragma solidity >=0.8.7;

error InvalidTemplate(address template);
error Forbidden();
error NotMintingTime();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {MetaTransactionVerifier} from "./MetaTransactionVerifier.sol";

contract NativeMetaTransaction is MetaTransactionVerifier {
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        uint256 nonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        verifyMetaTransaction(userAddress, functionSignature, nonce, sigR, sigS, sigV);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}