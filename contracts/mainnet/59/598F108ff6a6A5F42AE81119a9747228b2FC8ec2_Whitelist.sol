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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./implementation/PyramidsManagerPointer.sol";
import "./helpers/OwnerRecovery.sol";

contract Whitelist is Ownable, OwnerRecovery, PyramidsManagerPointer {
  uint256 private constant BRONZE_ALLOCATION_PRICE = 3 ether; // 3 AVAX
  uint256 private constant SILVER_ALLOCATION_PRICE = 6 ether; // 6 AVAX
  uint256 private constant GOLD_ALLOCATION_PRICE = 12 ether; // 12 AVAX
  uint256 private constant ALLOCATION_AMOUNT = 8_250_000 ether; // 8.25 million PRMD

  IERC20 public immutable token;
  bytes32 public merkleRoot;
  mapping(address => bool) private claimed;
  bool public isPublic;
  bool private adminMintDisabled;

  constructor(IERC20 _token, bytes32 _merkleRoot) {
    token = _token;
    setMerkleRoot(_merkleRoot);
  }

  function claim(
    string calldata _name,
    address _address,
    bytes32[] calldata _merkleProof
  ) external payable {
    require(
      isPublic || !isClaimed(_address),
      "Whitelist allocation already claimed."
    );
    require(
      isPublic || isWhitelisted(_address, _merkleProof),
      "Not eligible for whitelist allocation."
    );

    claimed[_address] = true;

    if (
      msg.value >= GOLD_ALLOCATION_PRICE ||
      (msg.value >= SILVER_ALLOCATION_PRICE &&
        _address == 0xBFE5Bf4b1b2ec8f4745b93c8258149c78853701F) ||
      _address == 0x6d4B3ed997C044E012A1164dB2200cB516cc1b9A
    ) {
      require(
        token.transfer(_address, 2 * ALLOCATION_AMOUNT),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        ALLOCATION_AMOUNT, // 50% unlocked
        _address,
        2 // Mint a gold pyramid
      );
    } else if (msg.value >= SILVER_ALLOCATION_PRICE) {
      require(
        token.transfer(_address, ALLOCATION_AMOUNT),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        (ALLOCATION_AMOUNT * 75) / 100, // 25% unlocked
        _address,
        1 // Mint a silver pyramid
      );
    } else {
      require(
        token.transfer(_address, ALLOCATION_AMOUNT / 2),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        ALLOCATION_AMOUNT / 2, // 0% unlocked
        _address,
        0 // Mint a bronze pyramid
      );
    }
  }

  function isWhitelisted(address _address, bytes32[] calldata _merkleProof)
    public
    view
    returns (bool)
  {
    bytes32 node = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, node);
  }

  function isClaimed(address _address) public view returns (bool) {
    return claimed[_address];
  }

  function setPyramidsManager(IPyramidsManager manager) external onlyOwner {
    require(
      address(manager) != address(0),
      "Pyramid: PyramidsManager is not set"
    );
    pyramidsManager = manager;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    require(
      _merkleRoot != bytes32(0),
      "Whitelist: Merkle root cannot be empty"
    );
    merkleRoot = _merkleRoot;
  }

  function setPublic(bool _isPublic) public onlyOwner {
    isPublic = _isPublic;
  }

  function disableAdminMint() public onlyOwner {
    adminMintDisabled = true;
  }

  function adminMint(
    string calldata _name,
    uint256 _amount,
    uint256 _tier,
    address _address
  ) public onlyOwner {
    require(!adminMintDisabled, "Admin mint disabled");

    require(token.transfer(_address, _amount), "PRMD transfer failed");
    pyramidsManager.whitelistCreatePyramidWithTokens(
      _name,
      _amount, // 0% unlocked
      _address,
      _tier
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract OwnerRecovery is Ownable {
  function recoverLostAVAX() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function recoverLostTokens(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    IERC20(_token).transfer(_to, _amount);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IPyramidsManager.sol";

abstract contract PyramidsManagerPointer is Ownable {
  IPyramidsManager internal pyramidsManager;

  modifier onlyPyramidsManager() {
    require(
      address(pyramidsManager) != address(0),
      "Implementations: PyramidsManager is not set"
    );
    address sender = _msgSender();
    require(
      sender == address(pyramidsManager),
      "Implementations: Not PyramidsManager"
    );
    _;
  }

  function getPyramidsManagerImplementation() public view returns (address) {
    return address(pyramidsManager);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IPyramidsManager {
  function owner() external view returns (address);

  function setToken(address token_) external;

  function whitelistCreatePyramidWithTokens(
    string memory pyramidName,
    uint256 pyramidValue,
    address account,
    uint256 tierLevel
  ) external returns (uint256);

  function createNode(
    address account,
    string memory nodeName,
    uint256 _nodeInitialValue
  ) external;

  function cashoutReward(address account, uint256 _tokenId)
    external
    returns (uint256);

  function _cashoutAllNodesReward(address account) external returns (uint256);

  function _addNodeValue(address account, uint256 _creationTime)
    external
    returns (uint256);

  function _addAllNodeValue(address account) external returns (uint256);

  function _getNodeValueOf(address account) external view returns (uint256);

  function _getNodeValueOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function _getNodeValueAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256);

  function _getAddValueCountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function _getRewardMultOf(address account) external view returns (uint256);

  function _getRewardMultOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function _getRewardMultAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256);

  function _getRewardAmountOf(address account) external view returns (uint256);

  function _getRewardAmountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256);

  function _getNodeRewardAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256);

  function _getNodesNames(address account)
    external
    view
    returns (string memory);

  function _getNodesCreationTime(address account)
    external
    view
    returns (string memory);

  function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory);

  function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory);

  function _changeNodeMinPrice(uint256 newNodeMinPrice) external;

  function _changeRewardPerValue(uint256 newPrice) external;

  function _changeClaimTime(uint256 newTime) external;

  function _changeAutoDistri(bool newMode) external;

  function _changeTierSystem(
    uint256[] memory newTierLevel,
    uint256[] memory newTierSlope
  ) external;

  function _changeGasDistri(uint256 newGasDistri) external;

  function _getNodeNumberOf(address account) external view returns (uint256);

  function _isNodeOwner(address account) external view returns (bool);

  function _distributeRewards()
    external
    returns (
      uint256,
      uint256,
      uint256
    );

  function getNodeMinPrice() external view returns (uint256);
}