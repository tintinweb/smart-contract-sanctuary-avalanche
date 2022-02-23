// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: afb3f89a535981fbe0239c38e369a473a1e3aee8;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRatesCalculator.sol";

/**
 * @title VariableUtilisationRatesCalculator
 * @dev Contract which calculates the interest rates based on pool utilisation.
 * Utilisation is computed as the ratio between funds borrowed and funds deposited to the pool.
 * Borrowing rates are calculated using a piecewise linear function. The first piece is defined by SLOPE_1
 * and OFFSET (shift). Second piece is defined by SLOPE_2 (calculated off-chain), BREAKPOINT (threshold value above
 * which second piece is considered) and MAX_RATE (value at pool utilisation of 1).
 **/
contract VariableUtilisationRatesCalculator is IRatesCalculator, Ownable {
  uint256 public constant SLOPE_1 = 0.12e18;
  uint256 public constant OFFSET = 0.05e18;
  // BREAKPOINT must be lower than 1e18
  uint256 public constant BREAKPOINT = 0.8e18;
  uint256 public constant MAX_RATE = 0.75e18;

  // calculated off-chain for gas efficiency with following formula:
  // (MAX_RATE - OFFSET - SLOPE_1 * BREAKPOINT) / (1 - BREAKPOINT)
  uint256 public constant SLOPE_2 = 3.02e18;

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * Returns the pool utilisation, which is a ratio between loans and deposits
   * utilisation = value_of_loans / value_of_deposits
   * @dev _totalLoans total value of loans
   * @dev _totalDeposits total value of deposits
   **/
  function getPoolUtilisation(uint256 _totalLoans, uint256 _totalDeposits) public pure returns (uint256) {
    if (_totalDeposits == 0) return 0;

    return (_totalLoans * 1e18) / _totalDeposits;
  }

  /**
   * Returns the current deposit rate
   * The value is based on the current borrowing rate and satisfies the invariant:
   * value_of_loans * borrowing_rate = value_of_deposits * deposit_rate
   * @dev _totalLoans total value of loans
   * @dev _totalDeposits total value of deposits
   **/
  function calculateDepositRate(uint256 _totalLoans, uint256 _totalDeposits) external view override returns (uint256) {
    if (_totalDeposits == 0) return 0;

    if (_totalLoans >= _totalDeposits) {
      return MAX_RATE;
    } else {
      return (this.calculateBorrowingRate(_totalLoans, _totalDeposits) * _totalLoans) / _totalDeposits;
    }
  }

  /**
   * Returns the current borrowing rate
   * The value is based on the pool utilisation according to the piecewise linear formula:
   * 1) for pool utilisation lower than or equal to breakpoint:
   * borrowing_rate = SLOPE_1 * utilisation + OFFSET
   * 2) for pool utilisation greater than breakpoint:
   * borrowing_rate = SLOPE_2 * utilisation + MAX_RATE - SLOPE_2
   * @dev _totalLoans total value of loans
   * @dev _totalDeposits total value of deposits
   **/
  function calculateBorrowingRate(uint256 totalLoans, uint256 totalDeposits) external view override returns (uint256) {
    if (totalDeposits == 0) return OFFSET;

    uint256 poolUtilisation = getPoolUtilisation(totalLoans, totalDeposits);

    if (poolUtilisation >= 1e18) {
      return MAX_RATE;
    } else if (poolUtilisation <= BREAKPOINT) {
      return (poolUtilisation * SLOPE_1) / 1e18 + OFFSET;
    } else {
      // full formula derived from piecewise linear function calculation except for SLOPE_2 subtraction (separated for
      // unsigned integer safety check)
      uint256 value = (poolUtilisation * SLOPE_2) / 1e18 + MAX_RATE;

      require(value >= SLOPE_2, "Out of range value when calculating the borrowing rate. Consider checking if SLOPE_2 is calculated correctly");

      return value - SLOPE_2;
    }
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

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.8.4;

/**
 * @title IRatesCalculator
 * @dev Interface defining base method for contracts implementing interest rates calculation.
 * The calculated value could be based on the relation between funds borrowed and deposited.
 */
interface IRatesCalculator {
  function calculateBorrowingRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);

  function calculateDepositRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);
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