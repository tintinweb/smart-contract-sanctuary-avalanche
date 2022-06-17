pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/BoringOwnable.sol";

/**
 * For simplicity, address(0) will be considered the address for native token.
 */
contract TokenDistributor is BoringOwnable {
  address public constant NATIVE_TOKEN_ADDRESS = address(0);

  event Deposit(address indexed tokenAddress, address indexed receivedFrom, uint256 amount);
  event Airdrop(address indexed tokenAddress, address indexed claimer, uint256 amount);
  event Claim(address indexed tokenAddress, address indexed claimer, uint256 amount);

  mapping(address => mapping(address => uint256)) private _unclaimedAmount;
  
  constructor() {}
  
  /**
   * Although address(0) is considered to be the address for the native token.
   * external methods (unclaimedAmount, totalBalance, airdrop, deposit, claim, etc.)
   * for ERC20s tokens and native tokens are different.
   */

  function unclaimedAmountNativeToken(address user) public view returns (uint256) {
    require(user != address(0), "User address must be non-zero");

    return _unclaimedAmount[NATIVE_TOKEN_ADDRESS][user];
  }

  function totalBalanceNativeToken() public view returns (uint256) {
    return address(this).balance;
  }

  function unclaimedAmountERC20(address tokenAddress, address user) public view returns (uint256) {
    require(tokenAddress != address(0), "Token address must be non-zero");
    require(user != address(0), "User address must be non-zero");

    return _unclaimedAmount[tokenAddress][user];
  }

  function totalBalanceERC20(address tokenAddress) public view returns (uint256) {
    require(tokenAddress != address(0), "Token address must be non-zero");

    return IERC20(tokenAddress).balanceOf(address(this));
  }

  /// Only way to deposit ethers; other ways such as call() or send() should revert
  function depositNativeToken() external payable {
    emit Deposit(NATIVE_TOKEN_ADDRESS, msg.sender, msg.value);
  }

  function airdropNativeToken(address claimer, uint256 amount) external onlyOwner {
    require(claimer != address(0), "Claimer address must be non-zero");

    _airdrop(NATIVE_TOKEN_ADDRESS, claimer, amount);
  }

  /// Internal variables are updated before call(), thus reentrancy attack are (or should be) avoided
  function claimNativeToken(uint256 amount) external {
    address claimer = msg.sender;
    require(unclaimedAmountNativeToken(claimer) >= amount, "Insufficient unclaimed amount");
    require(totalBalanceNativeToken() >= amount, "Insufficient total balance");

    _claim(NATIVE_TOKEN_ADDRESS, claimer, amount);
  }

  function claimAllNativeToken() external {
    address claimer = msg.sender;
    uint256 amount = unclaimedAmountNativeToken(claimer);
    require(totalBalanceNativeToken() >= amount, "Insufficient total balance");

    _claim(NATIVE_TOKEN_ADDRESS, claimer, amount);
  }

  /// Deposting directly through IERC20 should work fine as well
  /// Requires sender to approve transfer beforehand
  function depositERC20(address tokenAddress, uint256 amount) external {
    require(tokenAddress != address(0), "Token address must be non-zero");

    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    emit Deposit(tokenAddress, msg.sender, amount);
  }

  function airdropERC20(address tokenAddress, address claimer, uint256 amount) external onlyOwner {
    require(tokenAddress != address(0), "Token address must be non-zero");
    require(claimer != address(0), "Claimer address must be non-zero");

    _airdrop(tokenAddress, claimer, amount);
  }

  function claimERC20(address tokenAddress, uint256 amount) external {
    require(tokenAddress != address(0), "Token address must be non-zero");
    address claimer = msg.sender;

    require(unclaimedAmountERC20(tokenAddress, claimer) >= amount, "Insufficient unclaimed amount");
    require(totalBalanceERC20(tokenAddress) >= amount, "Insufficient total balance");

    _claim(tokenAddress, msg.sender, amount);
  }

  function claimAllERC20(address tokenAddress) external {
    require(tokenAddress != address(0), "Token address must be non-zero");

    address claimer = msg.sender;
    uint256 amount = unclaimedAmountERC20(tokenAddress, claimer);
    require(totalBalanceERC20(tokenAddress) >= amount, "Insufficient total balance");

    _claim(tokenAddress, claimer, amount);
  }

  function _airdrop(address tokenAddress, address claimer, uint256 amount) internal {
    _unclaimedAmount[tokenAddress][claimer] = amount;
    emit Airdrop(tokenAddress, claimer, amount);
  }

  /**
   * _claim() must be called ONLY when amount does NOT exceed unclaimed amount and total balance.
   * 
   * _claim() should be called AFTER every internal updates to avoid reentrancy attacks.
   */
  function _claim(address tokenAddress, address claimer, uint256 amount) internal {
    unchecked { 
      // assert(_unclaimedAmount[tokenAddress][claimer] >= amount);
      _unclaimedAmount[tokenAddress][claimer] -= amount;
    }

    if (tokenAddress == NATIVE_TOKEN_ADDRESS) {
      (bool success, ) = payable(claimer).call{value: amount}("");
      require(success, "Transfer unsuccessful");
    } else {
      IERC20(tokenAddress).transfer(claimer, amount);
    }

    emit Claim(tokenAddress, claimer, amount);
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
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}