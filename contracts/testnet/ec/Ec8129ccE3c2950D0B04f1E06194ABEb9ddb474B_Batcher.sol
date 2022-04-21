// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMeme {
  function balanceOf(address from) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface INFT {
  function balanceOf(address from) external view returns (uint256);

  function transfer(address to, uint256 tokenId) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IEumerable {
  function balanceOf(address owner) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract Batcher is Ownable {
  function transferTokens(
    IMeme[] calldata tokens,
    address to,
    uint256[] calldata amounts
  ) external {
    address from = msg.sender;
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i].transferFrom(from, to, amounts[i]);
    }
  }

  function distributeTokens(
    IMeme token,
    address[] calldata to,
    uint256[] calldata amounts
  ) external {
    address from = msg.sender;
    for (uint256 i = 0; i < to.length; i++) {
      token.transferFrom(from, to[i], amounts[i]);
    }
  }

  function batchTokens(
    IMeme[] calldata tokens,
    address[] calldata to,
    uint256[] calldata amounts
  ) external {
    address from = msg.sender;
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i].transferFrom(from, to[i], amounts[i]);
    }
  }

  function hatchTokens(IMeme[] calldata tokens) external onlyOwner {
    address to = owner();
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i].transfer(to, tokens[i].balanceOf(address(this)));
    }
  }

  function transferNFTs(
    INFT token,
    address to,
    uint256[] calldata tokenIds
  ) external {
    address from = msg.sender;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      token.transferFrom(from, to, tokenIds[i]);
    }
  }

  function transferEnumerables(
    IEumerable token,
    address to,
    uint256 amount
  ) external {
    address owner = msg.sender;
    uint256 balance = token.balanceOf(owner) - 1;
    for (uint256 i = 0; i < amount; i++) {
      token.transferFrom(msg.sender, to, token.tokenOfOwnerByIndex(owner, balance - i));
    }
  }

  function distributeNFTs(
    INFT token,
    address[] calldata to,
    uint256[] calldata tokenIds
  ) external {
    address from = msg.sender;
    for (uint256 i = 0; i < to.length; i++) {
      token.transferFrom(from, to[i], tokenIds[i]);
    }
  }

  function hatchNFTs(INFT token, uint256[] calldata tokenIds) external onlyOwner {
    address to = owner();
    for (uint256 i = 0; i < tokenIds.length; i++) {
      token.transfer(to, tokenIds[i]);
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