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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/6bd6b76d1156e20e45d1016f355d154141c7e5b9

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';

import {IBridgeWrapper} from '../interfaces/IBridgeWrapper.sol';

/**
 * @author BGD Labs
 * @dev Contract to wrap total supply of bridged tokens on Avalanche as there can possibly be
 * two bridges for one asset
 */
contract AvaxBridgeWrapper is IBridgeWrapper {
  // contract for the actual bridge
  IERC20Metadata private immutable _currentBridge;
  // contract for the deprecated bridge
  IERC20 private immutable _deprecatedBridge;

  /**
   * @notice Constructor.
   * @param currentBridgeAddress The address of the actual bridge for token
   * @param deprecatedBridgeAddress The address of the deprecated bridge for token
   */
  constructor(address currentBridgeAddress, address deprecatedBridgeAddress) {
    _currentBridge = IERC20Metadata(currentBridgeAddress);
    _deprecatedBridge = IERC20(deprecatedBridgeAddress);
  }

  /// @inheritdoc IBridgeWrapper
  function totalSupply() external view returns (uint256) {
    return _currentBridge.totalSupply() + _deprecatedBridge.totalSupply();
  }

  /// @inheritdoc IBridgeWrapper
  function name() external view returns (string memory) {
    return _currentBridge.name();
  }

  /// @inheritdoc IBridgeWrapper
  function symbol() external view returns (string memory) {
    return _currentBridge.symbol();
  }

  /// @inheritdoc IBridgeWrapper
  function decimals() external view returns (uint8) {
    return _currentBridge.decimals();
  }

  /// @inheritdoc IBridgeWrapper
  function getCurrentBridge() external view returns (address) {
    return address(_currentBridge);
  }

  /// @inheritdoc IBridgeWrapper
  function getDeprecatedBridge() external view returns (address) {
    return address(_deprecatedBridge);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgeWrapper {
  /**
   * @dev Returns the sum amount of tokens on deprecate and actual bridges.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the address of the current bridge.
   */
  function getCurrentBridge() external view returns (address);

  /**
   * @dev Returns the address of the deprecated bridge.
   */
  function getDeprecatedBridge() external view returns (address);
}