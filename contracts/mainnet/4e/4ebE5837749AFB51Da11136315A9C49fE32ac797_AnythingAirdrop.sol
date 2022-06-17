// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAnythingAirdrop.sol";
import "./libraries/TransferHelper.sol";
import "./BoringOwnable.sol";

contract AnythingAirdrop is BoringOwnable, IAnythingAirdrop {
  //Please refer to IAnythingAirdrop for events emitted

  /*Instead of depositing money into the smart contract and then call functions to allocate the money to people accordingly,
    AnythingAirdrop will ask for a transfer from the user according to the allocation given
    Idk if this is better but it is what I thought of initially
  */
  //mapping of recepientAddress => tokenAddress => claimAmount
  mapping(address => mapping(address => uint256)) private tokenDistribution;

  constructor() {}

  modifier checkZeroAddress(address checkAddress) {
    require(checkAddress != address(0), "AnythingAirdrop: address given is 0 address");
    _;
  }

  function airdrop(
    address to,
    address tokenAddress,
    uint256 amount
  ) external payable onlyOwner {
    if (tokenAddress != address(0)) {
      require(msg.value == 0, "AnythingAirdrop: ETH given for ERC20 airdrop");
      _airdrop(to, tokenAddress, amount);
    }
    else {
      require(msg.value == amount, "AnythingAirdrop: ETH given is not equal to allocation");
      _depositETH(to, amount);
    }
  }

  /// @dev _airdrop() is not used because code is implemented differently -> gas optimized so only 1 external call of safeTransferFrom is executed to save gas.
  /// this function scales linearly only with SSTORE. O(x * SSTORE) instead of O(x *(SSTORE + EXTERNAL_SLOAD))
  function airdropMultiUserOneToken(
    address[] calldata toAddresses,
    address tokenAddress,
    uint256[] calldata dropAmount
  ) external payable onlyOwner {
    uint256 toLength = toAddresses.length;
    require(
      dropAmount.length == toLength,
      "AnythingAirdrop: Invalid input parameters given (Length does not match)"
    );
    if (tokenAddress != address(0)) {
      uint256 total;
      for (uint256 i = 0; i < toLength; i++) {
        total += dropAmount[i];
        _deposit(toAddresses[i], tokenAddress, dropAmount[i]);
      }
      TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), total);
    }
    else {
      uint256 totalETH = 0;
      uint256 rewards;
      for (uint256 i = 0; i < toLength; i++) {
        rewards = dropAmount[i];
        totalETH += rewards;
        _depositETH(toAddresses[i], rewards);
      }
      require(msg.value == totalETH, "AnythingAirdrop: ETH given is not equal to allocation");
    }
  }

  //You can't really reduce external calls for this :(
  function airdropOneUserMultiToken(
    address toAddress,
    address[] calldata tokenAddresses,
    uint256[] calldata dropAmount
  ) external onlyOwner {
    uint256 tokenAddrLength = tokenAddresses.length;
    require(
      dropAmount.length == tokenAddrLength,
      "AnythingAirdrop: Invalid input parameters given (Length does not match)"
    );
    for (uint256 i = 0; i < tokenAddrLength; i++) {
      _airdrop(toAddress, tokenAddresses[i], dropAmount[i]);
    }
  }

  function claim(
    address to,
    address tokenAddress,
    uint256 amount
  ) external {
    if (tokenAddress != address(0)) _claim(to, tokenAddress, amount);
    else _claimETH(to, amount);
  }

  function claimAll(
    address to,
    address[] calldata tokenAddresses,
    uint256[] calldata amount
  ) external {
    uint256 tokenAddrLength = tokenAddresses.length;
    require(
      amount.length == tokenAddrLength,
      "AnythingAirdrop: Invalid input parameters given (Length does not match)"
    );
    address tokenAddress;
    uint256 claimAmount;
    for (uint256 i = 0; i < tokenAddrLength; i++) {
      tokenAddress = tokenAddresses[i];
      claimAmount = amount[i];
      if (tokenAddress != address(0)) _claim(to, tokenAddress, claimAmount);
      else _claimETH(to, claimAmount);
    }
  }
  
  /// @notice Used to takeback an amount incorrectly given to a user(in case fat finger give wrong address or give wrong amount).
  /// Coincidentally also works as a way to reduce distribution for a user.
  function takeback(
    address from,
    address tokenAddress,
    uint256 amount
  ) external onlyOwner {
    _redeem(from, msg.sender, tokenAddress, amount);
    emit Takeback(from, msg.sender, tokenAddress, amount);
  }

  function takebackETH(address from, uint256 amount) external onlyOwner {
    _redeemETH(from, msg.sender, amount);
    emit Takeback(from, msg.sender, address(0), amount);
  }

  /// @notice Used to shift airdrop amounts around (e.g I want to shift 50 PENDLE rewards from user A to user B)
  /// If tokenAddress is address(0) it refers to ETH. -> collision of address(0) have been prevented in _deposit
  function shiftAround(address shiftFrom, address shiftTo, address tokenAddress, uint256 amount) external onlyOwner checkZeroAddress(shiftFrom) checkZeroAddress(shiftTo) {
    if (tokenAddress != address(0)) {
      uint256 allocatedAmount = getERC20Distribution(shiftFrom, tokenAddress);
      require(allocatedAmount >= amount, "AnythingAirdrop: shifting more ERC20 than allocation");
      unchecked {
        tokenDistribution[shiftFrom][tokenAddress] -= amount;
      }
      tokenDistribution[shiftTo][tokenAddress] += amount;
    }
    else {
      uint256 allocatedAmount = getETHDistribution(shiftFrom);
      require(allocatedAmount >= amount, "AnythingAirdrop: shifting more ETH than allocation");
      unchecked {
        tokenDistribution[address(0)][shiftFrom] -= amount;
      }
      tokenDistribution[address(0)][shiftTo] += amount;
    }
    emit ShiftAround(shiftFrom, shiftTo, tokenAddress, amount);
  }

  function _airdrop(address to, address tokenAddress, uint256 amount) internal {
    _deposit(to, tokenAddress, amount);
    TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amount);
  }

  function _deposit(
    address to,
    address tokenAddress,
    uint256 amount
  ) internal checkZeroAddress(to) checkZeroAddress(tokenAddress){
    //Should we trust that the TransferFrom function of the token smart contract will handle transfer to 0 address (hence no need to check to is 0 address) or do we have to enforce this?
    //when tokenAddress is 0, it refers to ETH, so it would good if there's no tokenAddress with 0 address
    //Why there's no safeTransferFrom in _deposit: so that batchdeposit is possible in airdropMultiUserOneToken (saving gas due to less external calls?)
    tokenDistribution[to][tokenAddress] += amount;
    emit Airdrop(to, tokenAddress, amount);
  }

  function _depositETH(address to, uint256 amount) internal checkZeroAddress(to){
    tokenDistribution[address(0)][to] += amount;
    emit Airdrop(to, address(0), amount);
  }

  function _claim(address to, address tokenAddress, uint256 amount) internal {
    _redeem(to, to, tokenAddress, amount);
    emit Claim(to, tokenAddress, amount);
  }

  function _claimETH(address to, uint256 amount) internal {
    _redeemETH(to, to, amount);
    emit Claim(to, address(0), amount);
  }

  function _redeem(address redeemFrom, address redeemTo, address tokenAddress, uint256 amount) internal checkZeroAddress(redeemFrom) checkZeroAddress(redeemTo){
    uint256 allocatedAmount = getERC20Distribution(redeemFrom, tokenAddress);
    require(allocatedAmount >= amount, "AnythingAirdrop: claiming more ERC20 than allocation");
    unchecked {
      tokenDistribution[redeemFrom][tokenAddress] -= amount;  
    }
    TransferHelper.safeTransfer(tokenAddress, redeemTo, amount);
  }

  function _redeemETH(address redeemFrom, address redeemTo, uint256 amount) internal checkZeroAddress(redeemFrom) checkZeroAddress(redeemTo){
    uint256 allocatedAmount = getETHDistribution(redeemFrom);
    require(allocatedAmount >= amount, "AnythingAirdrop: claiming more ETH than allocation");
    unchecked {
      tokenDistribution[address(0)][redeemFrom] -= amount;  
    }
    TransferHelper.safeTransferETH(redeemTo, amount);
  }

  function getERC20Distribution(address userAddress, address tokenAddress)
    public
    view
    returns (uint256 allocatedAmount)
  {
    return tokenDistribution[userAddress][tokenAddress];
  }

  function getETHDistribution(address userAddress)
    public
    view
    returns (uint256 allocatedAmount)
  {
    return tokenDistribution[address(0)][userAddress];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnythingAirdrop {
  event Airdrop(address indexed to, address indexed tokenAddress, uint256 dropAmount);
  event Claim(
    address indexed to,
    address indexed tokenAddress,
    uint256 amount
  );
  event Takeback(address indexed redeemFrom, address indexed redeemTo, address indexed tokenAddress, uint256 amount);
  event ShiftAround(address indexed shiftFrom, address indexed shiftTo, address indexed tokenAddress, uint256 amount);

  function airdrop(
    address to,
    address tokenAddress,
    uint256 amount
  ) external payable;

  function airdropMultiUserOneToken(
    address[] calldata toAddresses,
    address tokenAddress,
    uint256[] calldata dropAmount
  ) external payable;

  function airdropOneUserMultiToken(
    address toAddress,
    address[] calldata tokenAddresses,
    uint256[] calldata dropAmount
  ) external;

  function claim(
    address to,
    address tokenAddress,
    uint256 amount
  ) external;

  function claimAll(
    address to,
    address[] calldata tokenAddresses,
    uint256[] calldata amount
  ) external;

  function takeback(
    address from,
    address tokenAddress,
    uint256 amount
  ) external;

  function takebackETH(address from, uint256 amount) external;

  function shiftAround(address shiftFrom, address shiftTo, address tokenAddress, uint256 amount) external;

  function getERC20Distribution(address userAddress, address tokenAddress)
    external
    view
    returns (uint256 allocatedAmount);
  
  function getETHDistribution(address userAddress) external view returns (uint256 allocatedAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

import "../interfaces/IERC20Minimal.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
      /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transfer: transfer failed");
    }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::transferFrom: transferFrom failed"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}