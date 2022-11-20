// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IBankroll.sol";
import "../interfaces/IGasStation.sol";
import "../interfaces/IReferralVault.sol";
import "../interfaces/VRFCoordinatorV2InterfaceExtended.sol";

error NotAGuardian(address caller);
error GameHalted();
error InvalidPriceFeed();
error InvalidVRFCost();
error FailedVRFHarvest();

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

abstract contract BaseGameEvents {
    event UpdateChainlinkSettings(
        address coordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint256 vrfPremium
    );

    event UpdateGameSettings(uint256 houseEdge, uint256 bankrollShare);
    event UpdateBankroll(address newBankrollAddress);
    event UpdateMinBet(address newMinBetAddress);
    event UpdateFeeRouter(address newFeeRouterAddress);
    event UpdateVRFHarvester(address newHarvester);
    event UpdateReferral(address newReferral);
    /*  */
    event RequestRandomness(uint256 requestId, uint32 randomValues);
    event ReceiveRandomness(uint256 requestId, uint256[] randomValues);
    /*  */
    event DeductVRFFee(uint256 paid, uint256 est);
    event HarvestVRFFees(uint256 amount);
    event UpdateGuardian(address guardianAddress, bool state);
    event EmergencyHalted();
    event EmergencyStopped();
}

abstract contract BaseGame is BaseGameEvents, Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;
    /* Events */

    address internal _mockWETH =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH public WETH = IWETH(address(0));

    /* Chainlink Settings */
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2InterfaceExtended vrfCoordinator;

    struct ChainlinkConfig {
        uint64 subscriptionId;
        bytes32 keyHash;
        uint256 vrfPremium;
    }
    ChainlinkConfig public chainlinkConfig = ChainlinkConfig(0, 0, 10_200);

    struct SettingStruct {
        uint256 houseEdge;
        uint256 bankrollShare;
    }

    SettingStruct public settings = SettingStruct(250, 8000);

    IBankroll public bank;
    address public feeRouter;
    IReferralVault public referral;

    AggregatorV3Interface public linkPriceFeed;
    address public vrfHarvester;

    /* Guardian */
    bool public halted = false;
    mapping(address => bool) public guardians;

    /* Guardian */
    constructor(
        address _weth,
        uint64 _subId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _linkPriceFeed,
        address bankAddress,
        address feeRouterAddress
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        WETH = IWETH(_weth);
        chainlinkConfig.subscriptionId = _subId;
        chainlinkConfig.keyHash = _keyHash;
        vrfCoordinator = VRFCoordinatorV2InterfaceExtended(_vrfCoordinator);

        bank = IBankroll(bankAddress);
        feeRouter = feeRouterAddress;
        linkPriceFeed = AggregatorV3Interface(_linkPriceFeed);
    }

    /* Emergency Stuff */
    modifier IsNotHalted() {
        if (halted) {
            revert GameHalted();
        }
        _;
    }

    modifier onlyGuardian() {
        if (guardians[msg.sender] == false) {
            revert NotAGuardian(msg.sender);
        }
        _;
    }

    function editGuardian(address _address, bool _state) external onlyOwner {
        guardians[_address] = _state;
        emit UpdateGuardian(_address, _state);
    }

    function emergencyHalt() external onlyGuardian {
        halted = true;
        emit EmergencyHalted();
    }

    function resetEmergencyHalt() external onlyOwner {
        halted = false;
        emit EmergencyStopped();
    }

    /* Emergency Stuff */

    /* Owner */
    function setChainlinkSettings(
        address _vrfCoordinator,
        uint64 _subId,
        bytes32 _keyHash,
        uint256 _vrfPremium
    ) external onlyOwner {
        vrfCoordinator = VRFCoordinatorV2InterfaceExtended(_vrfCoordinator);
        chainlinkConfig.subscriptionId = _subId;
        chainlinkConfig.keyHash = _keyHash;
        chainlinkConfig.vrfPremium = _vrfPremium;

        emit UpdateChainlinkSettings(
            _vrfCoordinator,
            chainlinkConfig.subscriptionId,
            chainlinkConfig.keyHash,
            chainlinkConfig.vrfPremium
        );
    }

    function setGameSettings(uint256 _edge, uint256 _share) external onlyOwner {
        settings.houseEdge = _edge;
        settings.bankrollShare = _share;

        emit UpdateGameSettings(settings.houseEdge, settings.bankrollShare);
    }

    function changeBank(address newBank) external onlyOwner {
        bank = IBankroll(newBank);

        emit UpdateBankroll(newBank);
    }

    function changeFeeRouter(address newRouter) external onlyOwner {
        feeRouter = newRouter;

        emit UpdateFeeRouter(feeRouter);
    }

    function changeVRFHarvester(address newHarvester) external onlyOwner {
        vrfHarvester = newHarvester;
        emit UpdateVRFHarvester(newHarvester);
    }

    function changeReferral(address newReferral) external onlyOwner {
        referral = IReferralVault(newReferral);
        emit UpdateReferral(newReferral);
    }

    function recoverTokens(address token) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    /* Owner */

    /* VRF */
    function harvestVRFCost() external {
        require(vrfHarvester != address(0), "No Harvester");
        uint256 balance = address(this).balance;
        IGasStation(vrfHarvester).topUp{value: balance}(
            address(vrfCoordinator),
            chainlinkConfig.subscriptionId,
            msg.sender
        );
        emit HarvestVRFFees(balance);
    }

    function _deductVRFCost(uint256 sentVRFGas, uint256 callbackGasLimit)
        internal
    {
        uint256 VRFCost = getVRFCost(callbackGasLimit);

        if (sentVRFGas < (VRFCost - ((VRFCost * 5) / 100))) {
            revert InvalidVRFCost();
        }

        emit DeductVRFFee(sentVRFGas, VRFCost);
    }

    function _requestRandomValues(uint32 callbackGas, uint32 randomValues)
        internal
        returns (uint256 requestId)
    {
        (uint16 minimumRequestConfirmations, , , ) = vrfCoordinator.getConfig();
        requestId = vrfCoordinator.requestRandomWords(
            chainlinkConfig.keyHash,
            chainlinkConfig.subscriptionId,
            minimumRequestConfirmations,
            callbackGas,
            randomValues
        );
        emit RequestRandomness(requestId, randomValues);

        return requestId;
    }

    function getVRFCost(uint256 callbackGasLimit)
        public
        view
        returns (uint256)
    {
        (, int256 unitsPerLink, , , ) = linkPriceFeed.latestRoundData();
        if (unitsPerLink == 0) revert InvalidPriceFeed();
        (uint32 fulfillmentFlatFeeLinkPPMTier1, , , , , , , , ) = vrfCoordinator
            .getFeeConfig();
        (, , , uint32 gasAfterPaymentCalculation) = vrfCoordinator.getConfig();

        uint256 callGasCost = tx.gasprice *
            (gasAfterPaymentCalculation + callbackGasLimit);
        uint256 vrfCost = (1e12 *
            uint256(fulfillmentFlatFeeLinkPPMTier1) *
            uint256(unitsPerLink)) / 1e18;

        return
            ((callGasCost + vrfCost) * (chainlinkConfig.vrfPremium)) / 10_000;
    }

    /* VRF */

    /* Gas Token */

    function _isGas(address token) internal view returns (bool) {
        return token == address(_mockWETH);
    }

    function _getAsset(address token) internal view returns (address) {
        if (_isGas(token)) return address(WETH);
        return token;
    }

    function _convertFromGasToken(
        address betToken,
        uint256 betAmount,
        uint256 gas
    )
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        if (_isGas(betToken) == false) return (false, betToken, gas);
        require(gas > betAmount, "insufficient gas");

        WETH.deposit{value: betAmount}();
        return (true, address(WETH), gas - betAmount);
    }

    function _convertToGasToken(uint256 betAmount) internal {
        WETH.withdraw(betAmount);
    }

    function _getReferralId(string memory code, address player)
        internal
        view
        returns (uint256)
    {
        if (address(referral) != address(0)) {
            return referral.getCodeId(code, player);
        }
        return 0;
    }

    /* Gas Token */
    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IBankroll.sol";
import "./BaseGame.sol";

error InvalidBetAmount();
error InvalidBetOptions();
error NoBankrollPool(address token);
error BetAlreadySettled(uint256 bet_id);
error BetNotFound(uint256 bet_id);
error BetNotExpired(uint256 bet_id);

contract DiceGame is BaseGame, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event NewBetResult(
        address indexed player,
        uint256 indexed gameId,
        uint256 randomness,
        bool win,
        uint256 result,
        uint16[] betOn,
        address betAsset,
        uint256 betAmount,
        uint256 winAmount
    );

    event NewBet(
        address indexed player,
        uint256 indexed gameId,
        address asset,
        uint256 amount,
        uint16[] options,
        string referalCode
    );

    struct GameStruct {
        uint32 timestamp; //uint32 is valid until 2016
        uint32 betId;
        bool settled;
        address player;
        address asset;
        uint256 amount;
        uint16[] betOn;
        uint256 randomId;
        uint256 result;
        bool refund;
        bool fundsSent;
        uint256 referralId;
    }

    uint256 public betCount = 0;

    mapping(uint256 => GameStruct) public bets;
    mapping(uint256 => uint256) private _randomCache;

    mapping(address => mapping(uint256 => uint256)) public playerBets;
    mapping(address => uint256) public playerBetCount;

    uint8 internal modulo = 6;

    constructor(
        address _weth,
        uint64 _subId,
        address vrfCoordinator,
        bytes32 keyHash,
        address linkPriceFeed,
        address feeRouterAddress,
        address bankAddress
    )
        BaseGame(
            _weth,
            _subId,
            vrfCoordinator,
            keyHash,
            linkPriceFeed,
            bankAddress,
            feeRouterAddress
        )
    {}

    /* Betting functions */
    function placeBet(
        address betAsset,
        uint256 amount,
        uint16[] calldata options,
        string calldata referalCode
    ) external payable nonReentrant IsNotHalted {
        (bool transferred, address asset, uint256 gas) = _convertFromGasToken(
            betAsset,
            amount,
            msg.value
        );
        _deductVRFCost(gas, 500_000);

        if (!bank.hasPool(asset)) {
            revert NoBankrollPool(asset);
        }
        if (amount == 0) {
            revert InvalidBetAmount();
        }

        uint256 betSum = getSum(options);
        if ((options.length != modulo) || (betSum == 0) || (betSum >= modulo)) {
            revert InvalidBetOptions();
        }

        uint256 maxWin = getWinAmount(amount, betSum);
        bank.reserveDebt(asset, maxWin - amount);

        // we dont need to transfer if transferred == true cuz msg.value
        if (!transferred) {
            IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }

        betCount += 1;
        // Request random number
        uint256 requestId = _requestRandomValues(500_000, 1);
        _randomCache[requestId] = betCount;
        bets[betCount] = GameStruct(
            uint32(block.timestamp),
            uint32(betCount),
            false,
            msg.sender,
            betAsset,
            amount,
            options,
            requestId,
            0,
            false,
            false,
            _getReferralId(referalCode, msg.sender)
        );

        playerBetCount[msg.sender] += 1;
        playerBets[msg.sender][playerBetCount[msg.sender]] = betCount;

        emit NewBet(msg.sender, betCount, asset, amount, options, referalCode);
    }

    function settle(uint256 gameId) external {
        GameStruct memory bet = bets[gameId];

        if (bet.betId == 0) {
            revert BetNotFound(gameId);
        }
        uint256 winAmount = getWinAmount(bet.amount, getSum(bet.betOn));

        address betAsset = _getAsset(bet.asset);
        bool isGas = _isGas(bet.asset);

        if ((bet.settled == false) && (bet.fundsSent == false)) {
            bets[gameId].settled = true;
            bets[gameId].refund = true;
            bets[gameId].fundsSent = true;

            if ((bet.timestamp + 2 * 60) > block.timestamp) {
                revert BetNotExpired(gameId);
            }

            bank.clearDebt(betAsset, winAmount - bet.amount);

            if (isGas) {
                _convertToGasToken(bet.amount);
                (bool sent, ) = bet.player.call{value: bet.amount}("");
                require(sent, "failed to send gastoken");
            } else {
                IERC20(betAsset).transfer(bet.player, bet.amount);
            }
        } else if ((bet.settled == true) && (bet.fundsSent == false)) {
            bets[gameId].settled = true;
            bets[gameId].fundsSent = true;

            bank.payDebt(
                isGas ? address(this) : bet.player,
                betAsset,
                winAmount - bet.amount
            );

            if (isGas) {
                _convertToGasToken(winAmount);
                (bool sent, ) = bet.player.call{value: winAmount}("");
                require(sent, "failed to send gastoken");
            } else {
                IERC20(bet.asset).transfer(bet.player, bet.amount);
            }
        } else {
            revert BetAlreadySettled(gameId);
        }
    }

    function fulfillRandomWords(uint256 randomId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 id = _randomCache[randomId];
        GameStruct memory bet = bets[id];
        if (bet.betId == 0 || id == 0) {
            revert BetNotFound(id);
        }
        if (bet.settled == true) {
            revert BetAlreadySettled(id);
        }
        uint256 winAmount = getWinAmount(bet.amount, getSum(bet.betOn));

        uint256 result = uint8(randomWords[0] % modulo);
        bets[id].result = result;

        bool _hasWon = hasWon(bet.betOn, result);
        if (_hasWon == true) {
            bool isGas = _isGas(bet.asset);

            // try to pay debt and if throws it marks it as pending
            // check isGas in case the user betted gasToken, thus we need to unwrap
            try
                bank.payDebt(
                    isGas ? address(this) : bet.player,
                    _getAsset(bet.asset),
                    winAmount - bet.amount
                )
            {
                bets[id].settled = true;
                bets[id].fundsSent = true;

                if (isGas) {
                    _convertToGasToken(winAmount);
                    (bool sent, ) = bet.player.call{value: winAmount}("");
                    require(sent, "failed to send gastoken");
                } else {
                    IERC20(bet.asset).transfer(bet.player, bet.amount);
                }
            } catch {
                bets[id].settled = true;
                bets[id].fundsSent = false;
            }
        } else {
            bets[id].settled = true;
            bets[id].fundsSent = true;

            address betAsset = _getAsset(bet.asset);
            bank.clearDebt(betAsset, winAmount - bet.amount);
            // Bankroll Share

            /* Amount to feed back into bankroll */
            uint256 bankrollShare = (bet.amount *
                (10000 - settings.houseEdge)) / 10000;
            uint256 houseShare = (bet.amount - bankrollShare);

            uint256 referralShare = 0;
            if (bet.referralId > 0) {
                if (address(referral) != address(0)) {
                    referralShare =
                        (houseShare *
                            referral.getReferralShare(bet.referralId)) /
                        10000;

                    houseShare -= referralShare;

                    /* Approve & Transfer to referral */
                    IERC20(betAsset).approve(address(referral), referralShare);
                    referral.deposit(
                        referralShare,
                        bet.player,
                        betAsset,
                        bet.referralId
                    );
                }
            }

            // Bankroll Share
            uint256 brshare = (houseShare * settings.bankrollShare) / 10000;

            /* Transfer to Bankroll */
            IERC20(betAsset).transfer(
                address(bank.pools(betAsset)),
                (bankrollShare + brshare)
            );

            // fee sharing to feeRouter
            uint256 veshare = bet.amount -
                (bankrollShare + brshare + referralShare);

            /* Transfer to feeRouter */
            IERC20(betAsset).transfer(feeRouter, veshare);
        }

        emit NewBetResult(
            bet.player,
            bet.betId,
            randomWords[0],
            _hasWon,
            result,
            bet.betOn,
            bet.asset,
            bet.amount,
            _hasWon ? winAmount : 0
        );
    }

    /* Betting functions end */

    function getBet(uint256 betId) public view returns (GameStruct memory) {
        return bets[betId];
    }

    function getPendingBets(address user, uint256 limit)
        public
        view
        returns (GameStruct[] memory)
    {
        uint256 i = 0;

        uint256 userBets = playerBetCount[user];
        if (limit > userBets) limit = userBets;

        GameStruct[] memory a = new GameStruct[](limit);

        for (uint256 userGameId = userBets; userGameId > 0; userGameId--) {
            uint256 gameId = playerBets[user][userGameId];
            GameStruct memory bet = bets[gameId];
            if ((bet.settled == false) && (bet.player == user)) {
                if (i >= limit) break;
                a[i] = bet;
                i++;
            }
        }
        return a;
    }

    function getWinAmount(uint256 betAmount, uint256 betSum)
        internal
        view
        returns (uint256)
    {
        uint256 _houseEdge = (betAmount * settings.houseEdge) / 10000;
        return ((betAmount - _houseEdge) * modulo) / betSum;
    }

    function getSum(uint16[] memory options) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint8 index = 0; index < modulo; index++) {
            sum += options[index];
        }
        return sum;
    }

    function hasWon(uint16[] memory options, uint256 winNumber)
        internal
        view
        returns (bool win)
    {
        win = false;

        for (uint8 index = 0; index < modulo; index++) {
            if (win) break;
            if (options[index] == 1 && winNumber == index) {
                win = true;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IBankroll {
  function addPool ( address token ) external;
  function balanceOf ( address token, address user ) external view returns ( uint256 );
  function clearDebt ( address token, uint256 amount ) external;
  function debtPools ( address ) external view returns ( uint256 );
  function deposit ( address token, uint256 amount ) external;
  function emergencyWithdraw ( address token ) external;
  function getMaxWin ( address token ) external view returns ( uint256 );
  function hasPool ( address token ) external view returns ( bool );
  function isWhitelisted ( address check ) external view returns ( bool );
  function max_win (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function payDebt ( address recipient, address token, uint256 amount ) external;
  function pools ( address ) external view returns ( address );
  function removePool ( address token ) external;
  function renounceOwnership (  ) external;
  function reserveDebt ( address token, uint256 amount ) external;
  function reserves ( address token ) external view returns ( uint256 );
  function setMaxWin ( uint256 new_max ) external;
  function setWhitelist ( address a, bool to ) external;
  function transferOwnership ( address newOwner ) external;
  function whitelistContracts ( address ) external view returns ( bool );
  function whitelistedTokens ( address ) external view returns ( bool );
  function withdraw ( address token, uint256 shares ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IGasStation {
	function topUp(address coordinator,uint64 subscriptionId,address caller) payable external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IReferralVault {
    function getCodeId(string memory code, address player)
        external
        view
        returns (uint256);

    function deposit(
        uint256 amount,
        address player,
        address token,
        uint256 nftId
    ) external;

    function getReferralShare(uint256 nftId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface VRFCoordinatorV2InterfaceExtended is VRFCoordinatorV2Interface{
    function getFeeConfig()
        external
        view
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5
        );

    function getConfig()
        external
        view
        returns (
            uint16 minimumRequestConfirmations,
            uint32 maxGasLimit,
            uint32 stalenessSeconds,
            uint32 gasAfterPaymentCalculation
        );
}