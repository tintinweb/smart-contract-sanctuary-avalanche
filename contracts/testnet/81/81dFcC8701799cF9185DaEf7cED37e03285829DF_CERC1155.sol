//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./erc1155/ERC1155.sol";

contract CERC1155 is ERC1155 {
  using Strings for uint256;

  address admin;
  string public baseURL;

  modifier onlyAdmin() {
    require(_msgSender() == admin, "not admin");
    _;
  }

  constructor(string memory initialBaseURL) ERC1155(initialBaseURL) {
    admin = _msgSender();
    baseURL = initialBaseURL;
  }

  /**
   * @dev Mint NFT and also check various conditions
   * 1. Only Admin can mint an NFT
   * @param _tokenId: the tokenID
   * @param _qty: quantity
   * @param _toAddress: receiver
   */
  function mintNFT(
    uint256 _tokenId,
    uint256 _qty,
    address _toAddress
  ) external {
    //onlyAdmin
    _mint(_toAddress, _tokenId, _qty, "");
  }

  /**
   * @dev Extension of {ERC1155} that allows to burn tokens
   */
  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    //onlyAdmin
    _burnBatch(account, ids, values);
  }

  /**
   * @dev chwon a token
   */
  function chown(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual {
    //
    adminChown(from, to, ids, amounts);
  }

  function setBaseURI(string memory newBaseURL) public {
    //onlyAdmin
    baseURL = newBaseURL;
  }

  /// @dev Returns the uri for a given tokenId.
  function uri(uint256 _tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURL, _tokenId.toString(), ".json"));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)
pragma solidity ^0.8.19;

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

abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

interface IERC1155 is IERC165 {
  /**
   * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
   */
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  /**
   * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
   * transfers.
   */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  /**
   * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
   * `approved`.
   */
  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
   *
   * If an {URI} event was emitted for `id`, the standard
   * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
   * returned by {IERC1155MetadataURI-uri}.
   */
  event URI(string value, uint256 indexed id);

  /**
   * @dev Returns the amount of tokens of token type `id` owned by `account`.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(
    address account,
    uint256 id
  ) external view returns (uint256);

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  /**
   * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
   *
   * Emits an {ApprovalForAll} event.
   *
   * Requirements:
   *
   * - `operator` cannot be the caller.
   */
  function setApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
   *
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(
    address account,
    address operator
  ) external view returns (bool);

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
   * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
   * Ensure to follow the checks-effects-interactions pattern and consider employing
   * reentrancy guards when interacting with untrusted contracts.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
   *
   *
   * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
   * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
   * Ensure to follow the checks-effects-interactions pattern and consider employing
   * reentrancy guards when interacting with untrusted contracts.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

interface IERC1155Receiver is IERC165 {
  /**
   * @dev Handles the receipt of a single ERC1155 token type. This function is
   * called at the end of a `safeTransferFrom` after the balance has been updated.
   *
   * NOTE: To accept the transfer, this must return
   * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * (i.e. 0xf23a6e61, or its own function selector).
   *
   * @param operator The address which initiated the transfer (i.e. msg.sender)
   * @param from The address which previously owned the token
   * @param id The ID of the token being transferred
   * @param value The amount of tokens being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  /**
   * @dev Handles the receipt of a multiple ERC1155 token types. This function
   * is called at the end of a `safeBatchTransferFrom` after the balances have
   * been updated.
   *
   * NOTE: To accept the transfer(s), this must return
   * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * (i.e. 0xbc197c81, or its own function selector).
   *
   * @param operator The address which initiated the batch transfer (i.e. msg.sender)
   * @param from The address which previously owned the token
   * @param ids An array containing ids of each token being transferred (order and length must match values array)
   * @param values An array containing amounts of each token being transferred (order and length must match ids array)
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {
  /**
   * @dev Returns the URI for token type `id`.
   *
   * If the `\{id\}` substring is present in the URI, it must be replaced by
   * clients with the actual token type ID.
   */
  function uri(uint256 id) external view returns (string memory);
}

/**
 * @dev Standard ERC20 Errors
 * Interface of the ERC6093 custom errors for ERC20 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC20Errors {
  /**
   * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   * @param balance Current balance for the interacting account.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC20InsufficientBalance(
    address sender,
    uint256 balance,
    uint256 needed
  );

  /**
   * @dev Indicates a failure with the token `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   */
  error ERC20InvalidSender(address sender);

  /**
   * @dev Indicates a failure with the token `receiver`. Used in transfers.
   * @param receiver Address to which tokens are being transferred.
   */
  error ERC20InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   * @param allowance Amount of tokens a `spender` is allowed to operate with.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC20InsufficientAllowance(
    address spender,
    uint256 allowance,
    uint256 needed
  );

  /**
   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
   * @param approver Address initiating an approval operation.
   */
  error ERC20InvalidApprover(address approver);

  /**
   * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   */
  error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the ERC6093 custom errors for ERC721 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC721Errors {
  /**
   * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
   * Used in balance queries.
   * @param owner Address of the current owner of a token.
   */
  error ERC721InvalidOwner(address owner);

  /**
   * @dev Indicates a `tokenId` whose `owner` is the zero address.
   * @param tokenId Identifier number of a token.
   */
  error ERC721NonexistentToken(uint256 tokenId);

  /**
   * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   * @param tokenId Identifier number of a token.
   * @param owner Address of the current owner of a token.
   */
  error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

  /**
   * @dev Indicates a failure with the token `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   */
  error ERC721InvalidSender(address sender);

  /**
   * @dev Indicates a failure with the token `receiver`. Used in transfers.
   * @param receiver Address to which tokens are being transferred.
   */
  error ERC721InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   * @param tokenId Identifier number of a token.
   */
  error ERC721InsufficientApproval(address operator, uint256 tokenId);

  /**
   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
   * @param approver Address initiating an approval operation.
   */
  error ERC721InvalidApprover(address approver);

  /**
   * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   */
  error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the ERC6093 custom errors for ERC1155 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC1155Errors {
  /**
   * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   * @param balance Current balance for the interacting account.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC1155InsufficientBalance(
    address sender,
    uint256 balance,
    uint256 needed,
    uint256 tokenId
  );

  /**
   * @dev Indicates a failure with the token `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   */
  error ERC1155InvalidSender(address sender);

  /**
   * @dev Indicates a failure with the token `receiver`. Used in transfers.
   * @param receiver Address to which tokens are being transferred.
   */
  error ERC1155InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   * @param owner Address of the current owner of a token.
   */
  error ERC1155InsufficientApprovalForAll(address operator, address owner);

  /**
   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
   * @param approver Address initiating an approval operation.
   */
  error ERC1155InvalidApprover(address approver);

  /**
   * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   */
  error ERC1155InvalidOperator(address operator);

  /**
   * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
   * Used in batch transfers.
   * @param idsLength Length of the array of token identifiers
   * @param valuesLength Length of the array of token amounts
   */
  error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Muldiv operation overflow.
   */
  error MathOverflowedMulDiv();

  enum Rounding {
    Down, // Toward negative infinity
    Up, // Toward infinity
    Zero // Toward zero
  }

  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v5.0._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v5.0._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v5.0._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v5.0._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v5.0._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0) {
      // Guarantee the same behavior as in a regular Solidity division.
      return a / b;
    }

    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a == 0 ? 0 : (a - 1) / b + 1;
  }

  /**
   * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
   * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
   * with further edits by Uniswap Labs also under MIT license.
   */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
      // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2^256 + prod0.
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division.
      if (prod1 == 0) {
        // Solidity will revert if denominator == 0, unlike the div opcode on its own.
        // The surrounding unchecked block does not change this fact.
        // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
        return prod0 / denominator;
      }

      // Make sure the result is less than 2^256. Also prevents denominator == 0.
      if (denominator <= prod1) {
        revert MathOverflowedMulDiv();
      }

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0].
      uint256 remainder;
      assembly {
        // Compute remainder using mulmod.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512 bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
      // See https://cs.stackexchange.com/q/138556/92363.

      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 twos = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by twos.
        denominator := div(denominator, twos)

        // Divide [prod1 prod0] by twos.
        prod0 := div(prod0, twos)

        // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
        twos := add(div(sub(0, twos), twos), 1)
      }

      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * twos;

      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;

      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256

      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }

  /**
   * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
   */
  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator,
    Rounding rounding
  ) internal pure returns (uint256) {
    uint256 result = mulDiv(x, y, denominator);
    if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
      result += 1;
    }
    return result;
  }

  /**
   * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
   *
   * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
   */
  function sqrt(uint256 a) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
    //
    // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
    // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
    //
    // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
    // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
    // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
    //
    // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
    uint256 result = 1 << (log2(a) >> 1);

    // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
    // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
    // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
    // into the expected uint128 result.
    unchecked {
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      result = (result + a / result) >> 1;
      return min(result, a / result);
    }
  }

  /**
   * @notice Calculates sqrt(a), following the selected rounding direction.
   */
  function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
    unchecked {
      uint256 result = sqrt(a);
      return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 2, rounded down, of a positive value.
   * Returns 0 if given 0.
   */
  function log2(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >> 128 > 0) {
        value >>= 128;
        result += 128;
      }
      if (value >> 64 > 0) {
        value >>= 64;
        result += 64;
      }
      if (value >> 32 > 0) {
        value >>= 32;
        result += 32;
      }
      if (value >> 16 > 0) {
        value >>= 16;
        result += 16;
      }
      if (value >> 8 > 0) {
        value >>= 8;
        result += 8;
      }
      if (value >> 4 > 0) {
        value >>= 4;
        result += 4;
      }
      if (value >> 2 > 0) {
        value >>= 2;
        result += 2;
      }
      if (value >> 1 > 0) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log2(
    uint256 value,
    Rounding rounding
  ) internal pure returns (uint256) {
    unchecked {
      uint256 result = log2(value);
      return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 10, rounded down, of a positive value.
   * Returns 0 if given 0.
   */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log10(
    uint256 value,
    Rounding rounding
  ) internal pure returns (uint256) {
    unchecked {
      uint256 result = log10(value);
      return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
    }
  }

  /**
   * @dev Return the log in base 256, rounded down, of a positive value.
   * Returns 0 if given 0.
   *
   * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
   */
  function log256(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >> 128 > 0) {
        value >>= 128;
        result += 16;
      }
      if (value >> 64 > 0) {
        value >>= 64;
        result += 8;
      }
      if (value >> 32 > 0) {
        value >>= 32;
        result += 4;
      }
      if (value >> 16 > 0) {
        value >>= 16;
        result += 2;
      }
      if (value >> 8 > 0) {
        result += 1;
      }
    }
    return result;
  }

  /**
   * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
   * Returns 0 if given 0.
   */
  function log256(
    uint256 value,
    Rounding rounding
  ) internal pure returns (uint256) {
    unchecked {
      uint256 result = log256(value);
      return
        result +
        (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
    }
  }
}

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant alphabet = "0123456789abcdef";

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
  function toHexString(
    uint256 value,
    uint256 length
  ) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = alphabet[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}

library StorageSlot {
  struct AddressSlot {
    address value;
  }

  struct BooleanSlot {
    bool value;
  }

  struct Bytes32Slot {
    bytes32 value;
  }

  struct Uint256Slot {
    uint256 value;
  }

  struct StringSlot {
    string value;
  }

  struct BytesSlot {
    bytes value;
  }

  /**
   * @dev Returns an `AddressSlot` with member `value` located at `slot`.
   */
  function getAddressSlot(
    bytes32 slot
  ) internal pure returns (AddressSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
   */
  function getBooleanSlot(
    bytes32 slot
  ) internal pure returns (BooleanSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
   */
  function getBytes32Slot(
    bytes32 slot
  ) internal pure returns (Bytes32Slot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
   */
  function getUint256Slot(
    bytes32 slot
  ) internal pure returns (Uint256Slot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `StringSlot` with member `value` located at `slot`.
   */
  function getStringSlot(
    bytes32 slot
  ) internal pure returns (StringSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
   */
  function getStringSlot(
    string storage store
  ) internal pure returns (StringSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := store.slot
    }
  }

  /**
   * @dev Returns an `BytesSlot` with member `value` located at `slot`.
   */
  function getBytesSlot(
    bytes32 slot
  ) internal pure returns (BytesSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := slot
    }
  }

  /**
   * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
   */
  function getBytesSlot(
    bytes storage store
  ) internal pure returns (BytesSlot storage r) {
    /// @solidity memory-safe-assembly
    assembly {
      r.slot := store.slot
    }
  }
}

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
  using StorageSlot for bytes32;

  /**
   * @dev Searches a sorted `array` and returns the first index that contains
   * a value greater or equal to `element`. If no such index exists (i.e. all
   * values in the array are strictly less than `element`), the array length is
   * returned. Time complexity O(log n).
   *
   * `array` is expected to be sorted in ascending order, and to contain no
   * repeated elements.
   */
  function findUpperBound(
    uint256[] storage array,
    uint256 element
  ) internal view returns (uint256) {
    if (array.length == 0) {
      return 0;
    }

    uint256 low = 0;
    uint256 high = array.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (unsafeAccess(array, mid).value > element) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
    if (low > 0 && unsafeAccess(array, low - 1).value == element) {
      return low - 1;
    } else {
      return low;
    }
  }

  /**
   * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
   *
   * WARNING: Only use if you are certain `pos` is lower than the array length.
   */
  function unsafeAccess(
    address[] storage arr,
    uint256 pos
  ) internal pure returns (StorageSlot.AddressSlot storage) {
    bytes32 slot;
    // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
    // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

    /// @solidity memory-safe-assembly
    assembly {
      mstore(0, arr.slot)
      slot := add(keccak256(0, 0x20), pos)
    }
    return slot.getAddressSlot();
  }

  /**
   * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
   *
   * WARNING: Only use if you are certain `pos` is lower than the array length.
   */
  function unsafeAccess(
    bytes32[] storage arr,
    uint256 pos
  ) internal pure returns (StorageSlot.Bytes32Slot storage) {
    bytes32 slot;
    // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
    // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

    /// @solidity memory-safe-assembly
    assembly {
      mstore(0, arr.slot)
      slot := add(keccak256(0, 0x20), pos)
    }
    return slot.getBytes32Slot();
  }

  /**
   * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
   *
   * WARNING: Only use if you are certain `pos` is lower than the array length.
   */
  function unsafeAccess(
    uint256[] storage arr,
    uint256 pos
  ) internal pure returns (StorageSlot.Uint256Slot storage) {
    bytes32 slot;
    // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
    // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

    /// @solidity memory-safe-assembly
    assembly {
      mstore(0, arr.slot)
      slot := add(keccak256(0, 0x20), pos)
    }
    return slot.getUint256Slot();
  }

  /**
   * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
   *
   * WARNING: Only use if you are certain `pos` is lower than the array length.
   */
  function unsafeMemoryAccess(
    uint256[] memory arr,
    uint256 pos
  ) internal pure returns (uint256 res) {
    assembly {
      res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
    }
  }

  /**
   * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
   *
   * WARNING: Only use if you are certain `pos` is lower than the array length.
   */
  function unsafeMemoryAccess(
    address[] memory arr,
    uint256 pos
  ) internal pure returns (address res) {
    assembly {
      res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
    }
  }
}

/* @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is
  Context,
  ERC165,
  IERC1155,
  IERC1155MetadataURI,
  IERC1155Errors
{
  using Arrays for uint256[];
  using Arrays for address[];

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  /**
   * @dev See {_setURI}.
   */
  constructor(string memory uri_) {
    _setURI(uri_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(
    address account,
    uint256 id
  ) public view virtual returns (uint256) {
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(
    address[] memory accounts,
    uint256[] memory ids
  ) public view virtual returns (uint256[] memory) {
    if (accounts.length != ids.length) {
      revert ERC1155InvalidArrayLength(ids.length, accounts.length);
    }

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(
        accounts.unsafeMemoryAccess(i),
        ids.unsafeMemoryAccess(i)
      );
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(
    address account,
    address operator
  ) public view virtual returns (bool) {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
      revert ERC1155InsufficientApprovalForAll(_msgSender(), from);
    }
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
      revert ERC1155InsufficientApprovalForAll(_msgSender(), from);
    }
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev admin can change ownership of a token
   * @param from - old owner
   * @param to - new owner
   * @param ids tokenIDs
   * @param amounts amounts
   */
  function adminChown(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal {
    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids.unsafeMemoryAccess(i);
      uint256 amount = amounts.unsafeMemoryAccess(i);

      if (from != address(0)) {
        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
          revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
        }
        unchecked {
          _balances[id][from] = fromBalance - amount;
        }
      }

      if (to != address(0)) {
        _balances[id][to] += amount;
      }
    }

    address operator = _msgSender();
    if (ids.length == 1) {
      uint256 id = ids.unsafeMemoryAccess(0);
      uint256 amount = amounts.unsafeMemoryAccess(0);
      emit TransferSingle(operator, from, to, id, amount);
      if (to != address(0)) {
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, "");
      }
    } else {
      emit TransferBatch(operator, from, to, ids, amounts);
      if (to != address(0)) {
        _doSafeBatchTransferAcceptanceCheck(
          operator,
          from,
          to,
          ids,
          amounts,
          ""
        );
      }
    }
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`. Will mint (or burn) if `from` (or `to`) is the zero address.
   *
   * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement either {IERC1155Receiver-onERC1155Received}
   *   or {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
   */
  function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    if (ids.length != amounts.length) {
      revert ERC1155InvalidArrayLength(ids.length, amounts.length);
    }

    address operator = _msgSender();

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids.unsafeMemoryAccess(i);
      uint256 amount = amounts.unsafeMemoryAccess(i);

      if (from != address(0)) {
        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
          revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
        }
        unchecked {
          _balances[id][from] = fromBalance - amount;
        }
      }

      if (to != address(0)) {
        _balances[id][to] += amount;
      }
    }

    if (ids.length == 1) {
      uint256 id = ids.unsafeMemoryAccess(0);
      uint256 amount = amounts.unsafeMemoryAccess(0);
      emit TransferSingle(operator, from, to, id, amount);
      if (to != address(0)) {
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
      }
    } else {
      emit TransferBatch(operator, from, to, ids, amounts);
      if (to != address(0)) {
        _doSafeBatchTransferAcceptanceCheck(
          operator,
          from,
          to,
          ids,
          amounts,
          data
        );
      }
    }
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to == address(0)) {
      revert ERC1155InvalidReceiver(address(0));
    }
    if (from == address(0)) {
      revert ERC1155InvalidSender(address(0));
    }
    (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(
      id,
      amount
    );
    _update(from, to, ids, amounts, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    if (to == address(0)) {
      revert ERC1155InvalidReceiver(address(0));
    }
    if (from == address(0)) {
      revert ERC1155InvalidSender(address(0));
    }
    _update(from, to, ids, amounts, data);
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * By this mechanism, any occurrence of the `\{id\}` substring in either the
   * URI or any of the amounts in the JSON file at said URI will be replaced by
   * clients with the token type ID.
   *
   * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
   * interpreted by clients as
   * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
   * for token type ID 0x4cce0.
   *
   * See {uri}.
   *
   * Because these URIs cannot be meaningfully represented by the {URI} event,
   * this function emits no events.
   */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to == address(0)) {
      revert ERC1155InvalidReceiver(address(0));
    }
    (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(
      id,
      amount
    );
    _update(address(0), to, ids, amounts, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    if (to == address(0)) {
      revert ERC1155InvalidReceiver(address(0));
    }
    _update(address(0), to, ids, amounts, data);
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `from`
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `from` must have at least `amount` tokens of token type `id`.
   */
  function _burn(address from, uint256 id, uint256 amount) internal {
    if (from == address(0)) {
      revert ERC1155InvalidSender(address(0));
    }
    (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(
      id,
      amount
    );
    _update(from, address(0), ids, amounts, "");
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal {
    if (from == address(0)) {
      revert ERC1155InvalidSender(address(0));
    }
    _update(from, address(0), ids, amounts, "");
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) {
      revert ERC1155InvalidOperator(operator);
    }
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try
        IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data)
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          // Tokens rejected
          revert ERC1155InvalidReceiver(to);
        }
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          // non-ERC1155Receiver implementer
          revert ERC1155InvalidReceiver(to);
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try
        IERC1155Receiver(to).onERC1155BatchReceived(
          operator,
          from,
          ids,
          amounts,
          data
        )
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          // Tokens rejected
          revert ERC1155InvalidReceiver(to);
        }
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          // non-ERC1155Receiver implementer
          revert ERC1155InvalidReceiver(to);
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  function _asSingletonArrays(
    uint256 element1,
    uint256 element2
  ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
    /// @solidity memory-safe-assembly
    assembly {
      array1 := mload(0x40)
      mstore(array1, 1)
      mstore(add(array1, 0x20), element1)

      array2 := add(array1, 0x40)
      mstore(array2, 1)
      mstore(add(array2, 0x20), element2)

      mstore(0x40, add(array2, 0x40))
    }
  }
}