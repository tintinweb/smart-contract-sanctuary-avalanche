// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124

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
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {AggregatorV3Interface} from 'chainlink-brownie-contracts/interfaces/AggregatorV3Interface.sol';

import {IProofOfReserveAggregator} from '../interfaces/IProofOfReserveAggregator.sol';

/**
 * @author BGD Labs
 * @dev Aave aggregator contract for Proof of Reserve Feeds and validations based on them:
 * - Indexes proof of reserve feed by token address
 * - Returns if all tokens of a list of assets are properly backed with Proof of Reserve logic, or not.
 */
contract ProofOfReserveAggregator is IProofOfReserveAggregator, Ownable {
  /// @dev token address => proof or reserve feed
  mapping(address => address) internal _proofOfReserveList;

  /// @dev token address = > bridge wrapper
  mapping(address => address) internal _bridgeWrapperList;

  /// @inheritdoc IProofOfReserveAggregator
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address)
  {
    return _proofOfReserveList[asset];
  }

  /// @inheritdoc IProofOfReserveAggregator
  function getBridgeWrapperForAsset(address asset)
    external
    view
    returns (address)
  {
    return _bridgeWrapperList[asset];
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external
    onlyOwner
  {
    require(asset != address(0), 'INVALID_ASSET');
    require(proofOfReserveFeed != address(0), 'INVALID_PROOF_OF_RESERVE_FEED');
    require(_proofOfReserveList[asset] == address(0), 'FEED_ALREADY_ENABLED');

    _proofOfReserveList[asset] = proofOfReserveFeed;
    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      address(0),
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address proofOfReserveFeed,
    address bridgeWrapper
  ) external onlyOwner {
    require(asset != address(0), 'INVALID_ASSET');
    require(proofOfReserveFeed != address(0), 'INVALID_PROOF_OF_RESERVE_FEED');
    require(bridgeWrapper != address(0), 'INVALID_BRIDGE_WRAPPER');
    require(_proofOfReserveList[asset] == address(0), 'FEED_ALREADY_ENABLED');

    _proofOfReserveList[asset] = proofOfReserveFeed;
    _bridgeWrapperList[asset] = bridgeWrapper;

    emit ProofOfReserveFeedStateChanged(
      asset,
      proofOfReserveFeed,
      bridgeWrapper,
      true
    );
  }

  /// @inheritdoc IProofOfReserveAggregator
  function disableProofOfReserveFeed(address asset) external onlyOwner {
    delete _proofOfReserveList[asset];
    delete _bridgeWrapperList[asset];
    emit ProofOfReserveFeedStateChanged(asset, address(0), address(0), false);
  }

  /// @inheritdoc IProofOfReserveAggregator
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory)
  {
    bool[] memory unbackedAssetsFlags = new bool[](assets.length);
    bool areReservesBacked = true;

    unchecked {
      for (uint256 i = 0; i < assets.length; ++i) {
        address assetAddress = assets[i];
        address feedAddress = _proofOfReserveList[assetAddress];
        address bridgeAddress = _bridgeWrapperList[assetAddress];
        address totalSupplyAddress = bridgeAddress != address(0)
          ? bridgeAddress
          : assetAddress;

        if (feedAddress != address(0)) {
          (, int256 answer, , , ) = AggregatorV3Interface(feedAddress)
            .latestRoundData();

          if (
            answer < 0 ||
            IERC20(totalSupplyAddress).totalSupply() > uint256(answer)
          ) {
            unbackedAssetsFlags[i] = true;
            areReservesBacked = false;
          }
        }
      }
    }

    return (areReservesBacked, unbackedAssetsFlags);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveAggregator {
  /**
   * @dev emitted when new asset and it's proof of reserve feed are enabled or disabled
   * @param asset the address of the asset
   * @param proofOfReserveFeed the address of the PoR feed
   * @param enabled whether it was enabled or disabled
   */
  event ProofOfReserveFeedStateChanged(
    address indexed asset,
    address indexed proofOfReserveFeed,
    address indexed bridgeWrapper,
    bool enabled
  );

  /**
   * @dev gets the address of the proof of reserve feed for the passed asset.
   * @param asset the address of the asset
   * @return address proof of reserve feed address
   */
  function getProofOfReserveFeedForAsset(address asset)
    external
    view
    returns (address);

  /**
   * @dev gets the address of the bridge wrapper for the passed asset.
   * @param asset the address of the asset
   * @return address the address of the bridge wrapper
   */
  function getBridgeWrapperForAsset(address asset)
    external
    view
    returns (address);

  /**
   * @dev add the asset and corresponding proof of reserve feed to the registry.
   * @param asset the address of the asset
   * @param proofOfReserveFeed the address of the proof of reserve aggregator feed
   */
  function enableProofOfReserveFeed(address asset, address proofOfReserveFeed)
    external;

  /**
   * @dev add the asset, bridge wrapper and corresponding proof of reserve feed to the registry
   * this method should be used for the assets with the existing deprecated bridge
   * @param asset the address of the asset
   * @param proofOfReserveFeed the address of the proof of reserve aggregator feed
   * @param bridgeWrapper the bridge wrapper for the asset
   */
  function enableProofOfReserveFeedWithBridgeWrapper(
    address asset,
    address proofOfReserveFeed,
    address bridgeWrapper
  ) external;

  /**
   * @dev delete the asset and the proof of reserve feed from the registry
   * @param asset address of the asset
   */
  function disableProofOfReserveFeed(address asset) external;

  /**
   * @dev returns if all the assets that have been passed are backed;
   * @param assets list of the assets to check
   * @return bool true if all of the assets are backed.
   * @return flags of the unbacked assets.
   */
  function areAllReservesBacked(address[] calldata assets)
    external
    view
    returns (bool, bool[] memory);
}