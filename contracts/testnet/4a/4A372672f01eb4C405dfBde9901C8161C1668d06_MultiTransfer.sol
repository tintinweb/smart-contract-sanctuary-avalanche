//SDPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPermit2} from "../utils/permit2/interfaces/IPermit2.sol";
import {ERC20} from "oz-custom/contracts/oz/token/ERC20/ERC20.sol";

interface IMultiTransfer {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitDetail {
        address token;
        address spender;
        uint48 deadline;
        address[] addresses;
    }

    // error
    error MultiTransfer_LengthMismatch();
    error MultiTransfer_InsufficientBalance();

    // event
    // event TokenTransfered(address indexed operator_, uint256[] success);
    event Permit2Changed(
        address indexed operator_,
        IPermit2 indexed from_,
        IPermit2 indexed to_
    );

    // event Permitted(address indexed operator_, address indexed spender_, uint256 indexed amount_, address[] addresses);

    // function
    function multiTransferETH(address[] calldata addresses_) external payable;

    function multiTransferERC20(
        address token_,
        address[] calldata addresses_,
        uint256 amount_
    ) external;

    function multiPermit(
        PermitDetail calldata details_,
        Signature[] calldata signatures_
    ) external;

    function multiPermit2(
        PermitDetail calldata details_,
        uint48 nonce_,
        bytes[] calldata signature_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library SafeTransferLib {
    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "TF");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TFF");
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TF");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeTransferLib} from "./libs/SafeTransferLib.sol";
import {Ownable} from "oz-custom/contracts/oz/access/Ownable.sol";
import {ERC20, IMultiTransfer} from "./interfaces/IMultiTransfer.sol";
import {IERC20, IPermit2} from "./utils/permit2/interfaces/IPermit2.sol";
import {IERC20Permit} from "oz-custom/contracts/oz/token/ERC20/extensions/IERC20Permit.sol";

contract MultiTransfer is Ownable, IMultiTransfer {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IPermit2 public permit2;

    function setPermit2(IPermit2 permit2_) external onlyOwner {
        emit Permit2Changed(_msgSender(), permit2, permit2_);
        permit2 = permit2_;
    }

    function multiTransferETH(
        address[] calldata addresses_
    ) external payable onlyOwner {
        address account;
        uint256 length = addresses_.length;
        uint256 amount = msg.value / length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            SafeTransferLib.safeTransferETH(account, amount);
            unchecked {
                ++i;
            }
        }
    }

    function multiTransferERC20(
        address token_,
        address[] calldata addresses_,
        uint256 amount_
    ) external onlyOwner {
        address account;
        uint256 length = addresses_.length;
        for (uint i = 0; i < length; ) {
            account = addresses_[i];
            SafeTransferLib.safeTransferFrom(
                token_,
                _msgSender(),
                account,
                amount_
            );
            unchecked {
                ++i;
            }
        }
    }

    function multiPermit(
        PermitDetail calldata details_,
        Signature[] calldata signatures_
    ) external onlyOwner {
        if (details_.addresses.length != signatures_.length)
            revert MultiTransfer_LengthMismatch();

        address account;
        uint256 length = details_.addresses.length;
        Signature memory sign;
        for (uint256 i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            IERC20Permit(details_.token).permit(
                account,
                details_.spender,
                MAX_INT,
                details_.deadline,
                sign.v,
                sign.r,
                sign.s
            );
            unchecked {
                ++i;
            }
        }
    }

    function multiPermit2(
        PermitDetail calldata details_,
        uint48 nonce_,
        bytes[] calldata signatures_
    ) external onlyOwner {
        if (details_.addresses.length != signatures_.length)
            revert MultiTransfer_LengthMismatch();

        IPermit2 _permit2 = permit2;
        uint256 length = details_.addresses.length;
        address account;
        bytes memory sign;
        for (uint i; i < length; ) {
            account = details_.addresses[i];
            sign = signatures_[i];
            _permit2.permit({
                owner: account,
                permitSingle: IPermit2.PermitSingle({
                    details: IPermit2.PermitDetails({
                        token: details_.token,
                        amount: uint160(MAX_INT),
                        expiration: details_.deadline,
                        nonce: nonce_
                    }),
                    spender: details_.spender,
                    sigDeadline: details_.deadline
                }),
                signature: sign
            });
            unchecked {
                ++i;
            }
        }
    }

    function withdraw(address token_, uint96 amount_) external onlyOwner {
        if (token_ == address(0)) {
            SafeTransferLib.safeTransferETH(_msgSender(), amount_);
        } else {
            SafeTransferLib.safeTransfer(token_, _msgSender(), amount_);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
pragma solidity 0.8.19;
import {IERC20} from "./IERC20.sol";

interface IPermit2 {
    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    // Token and amount in a permit message.
    struct TokenPermissions {
        // Token to transfer.
        IERC20 token;
        // Amount to transfer.
        uint256 amount;
    }

    // The permit2 message.
    struct PermitTransferFrom {
        // Permitted token and amount.
        TokenPermissions permitted;
        // Unique identifier for this permit.
        uint256 nonce;
        // Expiration for this permit.
        uint256 deadline;
    }

    // Transfer details for permitTransferFrom().
    struct SignatureTransferDetails {
        // Recipient of tokens.
        address to;
        // Amount to transfer.
        uint256 requestedAmount;
    }

    // Consume a permit2 message and transfer tokens.
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(
        address,
        address,
        address
    ) external view returns (uint160, uint48, uint48);

    // @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    // @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address addr) {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32 value) {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import {Context} from "../utils/Context.sol";
import {Bytes32Address} from "../../libraries/Bytes32Address.sol";

interface IOwnable {
    error Ownable__Unauthorized();
    error Ownable__NonZeroAddress();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address _owner);
}

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
abstract contract Ownable is Context, IOwnable {
    using Bytes32Address for *;

    bytes32 private __owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() payable {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address _owner) {
        assembly {
            _owner := sload(__owner.slot)
        }
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner(address sender_) internal view virtual {
        if (__owner != sender_.fillLast12Bytes())
            revert Ownable__Unauthorized();
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
        if (newOwner == address(0)) revert Ownable__Unauthorized();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        assembly {
            log3(
                0x00,
                0x00,
                /// @dev value is equal to kecak256("OwnershipTransferred(address,address)");
                0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0,
                sload(__owner.slot),
                newOwner
            )
            sstore(__owner.slot, newOwner)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../../utils/Context.sol";

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    string public name;
    string public symbol;

    mapping(address => uint256) internal _balanceOf;

    mapping(address => mapping(address => uint256)) internal _allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_) payable {
        if (bytes(symbol_).length > 32 || bytes(name_).length > 32)
            revert ERC20__StringTooLong();

        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool approved) {
        address sender = _msgSender();

        assembly {
            mstore(0x00, sender)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            sstore(keccak256(0x00, 0x40), amount)

            // emit Approval(sender, spender, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Approval(address,address,uint256)")
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                sender,
                spender
            )

            approved := true
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address sender = _msgSender();
        _beforeTokenTransfer(sender, to, amount);

        assembly {
            //  _balanceOf[sender] -= amount;
            mstore(0x00, sender)
            mstore(0x20, _balanceOf.slot)
            let balanceKey := keccak256(0x00, 0x40)
            let balanceBefore := sload(balanceKey)
            //  underflow check
            if gt(amount, balanceBefore) {
                revert(0, 0)
            }
            sstore(balanceKey, sub(balanceBefore, amount))

            //  _balanceOf[to] += amount;
            mstore(0x00, to)
            balanceKey := keccak256(0x00, 0x40)
            balanceBefore := sload(balanceKey)
            sstore(balanceKey, add(balanceBefore, amount))

            // emit Transfer(sender, to, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                sender,
                to
            )
        }

        _afterTokenTransfer(sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        _spendAllowance(from, _msgSender(), amount);

        assembly {
            //  @dev _balanceOf[from] -= amount;
            mstore(0x00, from)
            mstore(0x20, _balanceOf.slot)
            let balanceKey := keccak256(0x00, 0x40)
            let balanceBefore := sload(balanceKey)
            //  @dev underflow check
            if gt(amount, balanceBefore) {
                revert(0, 0)
            }
            sstore(balanceKey, sub(balanceBefore, amount))

            //  @dev Cannot overflow because the sum of all user
            //  balances can't exceed the max uint256 value.
            mstore(0x00, to)
            balanceKey := keccak256(0x00, 0x40)
            balanceBefore := sload(balanceKey)
            sstore(balanceKey, add(balanceBefore, amount))

            //  @dev emit Transfer(from, to, amount)
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                to
            )
        }

        _afterTokenTransfer(from, to, amount);

        return true;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256 _balance) {
        assembly {
            mstore(0x00, account)
            mstore(0x20, _balanceOf.slot)
            _balance := sload(keccak256(0x00, 0x40))
        }
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256 allowance_) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            allowance_ := sload(keccak256(0x00, 0x40))
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        assembly {
            mstore(0x00, owner_)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender_)
            let allowanceKey := keccak256(0x00, 0x40)
            let allowed := sload(allowanceKey)

            if iszero(
                eq(
                    allowed,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
            ) {
                //  underflow check
                if gt(amount_, allowed) {
                    revert(0, 0)
                }
                sstore(allowanceKey, sub(allowed, amount_))
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);

        assembly {
            //  @dev totalSupply += amount;
            let cachedVal := sload(totalSupply.slot)
            cachedVal := add(cachedVal, amount)
            //  @dev overflow check
            if lt(cachedVal, amount) {
                revert(0, 0)
            }
            sstore(totalSupply.slot, cachedVal)

            //  @dev Cannot overflow because the sum of all user
            //  balances can't exceed the max uint256 value.
            //  @dev _balanceOf[to] += amount;
            mstore(0x00, to)
            mstore(0x20, _balanceOf.slot)
            cachedVal := keccak256(0x00, 0x40)
            sstore(cachedVal, add(sload(cachedVal), amount))

            //  emit Transfer(address(0), to, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                0,
                to
            )
        }

        _afterTokenTransfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        assembly {
            //  @dev _balanceOf[from] -= amount;
            mstore(0, from)
            mstore(32, _balanceOf.slot)
            let key := keccak256(0, 64)
            let cachedVal := sload(key)
            // @dev underflow check
            if gt(amount, cachedVal) {
                revert(0, 0)
            }

            cachedVal := sub(cachedVal, amount)
            sstore(key, cachedVal)

            //  @dev totalSupply -= amount;
            //  @dev Cannot underflow because a user's balance
            //  @dev will never be larger than the total supply.
            key := totalSupply.slot
            cachedVal := sload(key)
            cachedVal := sub(cachedVal, amount)
            sstore(key, cachedVal)

            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                0
            )
        }

        _afterTokenTransfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import {IERC20} from "../IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.17;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    error ERC20Permit__Expired();

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error ERC20__StringTooLong();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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
    function _msgSender() internal view virtual returns (address sender) {
        assembly {
            sender := caller()
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}