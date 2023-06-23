// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.18;

import "./Counter.sol";
import "@hyperlane/solidity/contracts/libs/TypeCasts.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IMessageRecipient {
    /**
     * @notice Handle an interchain message
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external;
}

contract Recieve is IMessageRecipient {
    event Received(uint32 origin, address sender, bytes body);

    address constant mailbox = 0xCC737a94FecaeC165AbCf12dED095BB13F037685;

    modifier onlyMailbox() {
        require(msg.sender == mailbox);
        _;
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external onlyMailbox {
        (uint256 value, address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        = abi.decode(_body, (uint256, address, address, uint256, uint256, uint8, bytes32, bytes32));
        Counter counter = Counter(0x0e46caFAE2A3Aab7070A300ADd05077c18457098);
        IERC20Permit token = IERC20Permit(0xf500Fe3FeB50a807024299d9e2657D2c6142687c);
        counter.increment(value);
        token.permit(owner, spender, amount, deadline, v, r, s);
        address sender = TypeCasts.bytes32ToAddress(_sender);
        emit Received(_origin, sender, _body);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

interface Counter {
    function increment(uint256 value) external;

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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